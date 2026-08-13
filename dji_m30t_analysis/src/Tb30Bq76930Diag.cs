using System;
using System.Collections.Generic;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

namespace Tb30Bq76930Diag
{
    internal static class Native
    {
        private const string DllName = "SLABHIDtoSMBus.dll";

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_GetNumDevices(ref uint numDevices, ushort vid, ushort pid);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall, CharSet = CharSet.Ansi)]
        internal static extern int HidSmbus_GetString(uint deviceNum, ushort vid, ushort pid,
            StringBuilder deviceString, uint options);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_Open(ref IntPtr device, uint deviceNum, ushort vid, ushort pid);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_Close(IntPtr device);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_IsOpened(IntPtr device, ref int opened);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_GetPartNumber(IntPtr device, ref byte partNumber,
            ref byte version);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_SetSmbusConfig(IntPtr device, uint bitRate, byte ownAddress,
            int autoReadRespond, ushort writeTimeout, ushort readTimeout, int sclLowTimeout,
            ushort transferRetries);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_SetTimeouts(IntPtr device, uint responseTimeout);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_AddressReadRequest(IntPtr device, byte slaveAddress,
            ushort numBytesToRead, byte targetAddressSize, byte[] targetAddress);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_TransferStatusRequest(IntPtr device);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_GetTransferStatusResponse(IntPtr device, ref byte status,
            ref byte detailedStatus, ref ushort numRetries, ref ushort bytesRead);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_ForceReadResponse(IntPtr device, ushort numBytesToRead);

        [DllImport(DllName, CallingConvention = CallingConvention.StdCall)]
        internal static extern int HidSmbus_GetReadResponse(IntPtr device, ref byte status,
            byte[] buffer, byte bufferSize, ref byte numBytesRead);
    }

    internal sealed class Cp2112 : IDisposable
    {
        private IntPtr handle = IntPtr.Zero;

        internal static uint CountDevices(ushort vid, ushort pid)
        {
            uint count = 0;
            Check(Native.HidSmbus_GetNumDevices(ref count, vid, pid), "HidSmbus_GetNumDevices");
            return count;
        }

        internal static string GetSerial(uint index, ushort vid, ushort pid)
        {
            StringBuilder serial = new StringBuilder(260);
            Check(Native.HidSmbus_GetString(index, vid, pid, serial, 4), "HidSmbus_GetString(serial)");
            return serial.ToString();
        }

        internal Cp2112(uint index, ushort vid, ushort pid)
        {
            Check(Native.HidSmbus_Open(ref handle, index, vid, pid), "HidSmbus_Open");
            if (handle == IntPtr.Zero)
                throw new InvalidOperationException("CP2112 returned an empty handle.");
            try
            {
                byte partNumber = 0;
                byte version = 0;
                Check(Native.HidSmbus_GetPartNumber(handle, ref partNumber, ref version),
                    "HidSmbus_GetPartNumber");
                if (partNumber != 0x0C)
                    throw new InvalidOperationException(String.Format(CultureInfo.InvariantCulture,
                        "Selected HID device is not a CP2112 (part number 0x{0:X2}).", partNumber));

                // The CP2112 is only configured here. No battery register is written.
                Check(Native.HidSmbus_SetSmbusConfig(handle, 100000, 0x02, 0, 100, 100, 0, 10),
                    "HidSmbus_SetSmbusConfig");
                Check(Native.HidSmbus_SetTimeouts(handle, 250), "HidSmbus_SetTimeouts");
            }
            catch
            {
                Native.HidSmbus_Close(handle);
                handle = IntPtr.Zero;
                throw;
            }
        }

        internal byte[] ReadAddressed(byte writeAddress, byte register, int count)
        {
            if ((writeAddress & 1) != 0)
                throw new ArgumentException("The CP2112 API requires an even 8-bit write address.");
            if (count < 1 || count > 61)
                throw new ArgumentOutOfRangeException("count", "One CP2112 response supports 1..61 bytes.");

            byte[] target = new byte[] { register };
            Check(Native.HidSmbus_AddressReadRequest(handle, writeAddress, (ushort)count, 1, target),
                "HidSmbus_AddressReadRequest");

            byte transferStatus = 0;
            byte detailedStatus = 0;
            ushort retries = 0;
            ushort bytesRead = 0;
            bool complete = false;
            for (int attempt = 0; attempt < 40; attempt++)
            {
                Check(Native.HidSmbus_TransferStatusRequest(handle), "HidSmbus_TransferStatusRequest");
                Check(Native.HidSmbus_GetTransferStatusResponse(handle, ref transferStatus,
                    ref detailedStatus, ref retries, ref bytesRead), "HidSmbus_GetTransferStatusResponse");
                if (transferStatus == 2)
                {
                    complete = true;
                    break;
                }
                if (transferStatus == 3 || transferStatus == 0)
                    throw new InvalidOperationException(String.Format(CultureInfo.InvariantCulture,
                        "SMBus transfer failed: status={0}, detail=0x{1:X2}, retries={2}, bytes={3}.",
                        transferStatus, detailedStatus, retries, bytesRead));
                Thread.Sleep(2);
            }
            if (!complete)
                throw new TimeoutException("SMBus transfer did not complete within the bounded polling interval.");

            Check(Native.HidSmbus_ForceReadResponse(handle, (ushort)count), "HidSmbus_ForceReadResponse");
            List<byte> result = new List<byte>(count);
            for (int attempt = 0; attempt < 40 && result.Count < count; attempt++)
            {
                byte responseStatus = 0;
                byte responseCount = 0;
                byte[] chunk = new byte[61];
                Check(Native.HidSmbus_GetReadResponse(handle, ref responseStatus, chunk, 61,
                    ref responseCount), "HidSmbus_GetReadResponse");
                for (int i = 0; i < responseCount && result.Count < count; i++)
                    result.Add(chunk[i]);
                if (responseCount == 0)
                    Thread.Sleep(2);
            }
            if (result.Count != count)
                throw new TimeoutException(String.Format(CultureInfo.InvariantCulture,
                    "Expected {0} bytes, received {1}.", count, result.Count));
            return result.ToArray();
        }

        public void Dispose()
        {
            if (handle != IntPtr.Zero)
            {
                Native.HidSmbus_Close(handle);
                handle = IntPtr.Zero;
            }
        }

        private static void Check(int status, string operation)
        {
            if (status != 0)
                throw new InvalidOperationException(String.Format(CultureInfo.InvariantCulture,
                    "{0} failed with HID-SMBus status 0x{1:X2}.", operation, status));
        }
    }

    internal sealed class Bq76930
    {
        private readonly Cp2112 bridge;
        private readonly byte writeAddress;
        private readonly bool crcEnabled;

        internal Bq76930(Cp2112 bridge, byte sevenBitAddress, bool crcEnabled)
        {
            this.bridge = bridge;
            this.writeAddress = (byte)(sevenBitAddress << 1);
            this.crcEnabled = crcEnabled;
        }

        internal byte[] Read(byte register, int count)
        {
            int rawCount = crcEnabled ? checked(count * 2) : count;
            byte[] raw = bridge.ReadAddressed(writeAddress, register, rawCount);
            if (!crcEnabled)
                return raw;

            byte[] data = new byte[count];
            for (int i = 0; i < count; i++)
            {
                data[i] = raw[i * 2];
                byte expected = i == 0
                    ? Crc8(new byte[] { (byte)(writeAddress | 1), data[i] })
                    : Crc8(new byte[] { data[i] });
                byte actual = raw[(i * 2) + 1];
                if (expected != actual)
                    throw new InvalidOperationException(String.Format(CultureInfo.InvariantCulture,
                        "CRC mismatch at register 0x{0:X2}: expected 0x{1:X2}, got 0x{2:X2}.",
                        register + i, expected, actual));
            }
            return data;
        }

        internal static bool LooksLikeCrcFrame(byte writeAddress, byte[] raw)
        {
            if (raw == null || raw.Length < 4)
                return false;
            return raw[1] == Crc8(new byte[] { (byte)(writeAddress | 1), raw[0] })
                && raw[3] == Crc8(new byte[] { raw[2] });
        }

        internal static byte Crc8(byte[] bytes)
        {
            byte crc = 0;
            for (int i = 0; i < bytes.Length; i++)
            {
                crc ^= bytes[i];
                for (int bit = 0; bit < 8; bit++)
                    crc = (byte)(((crc & 0x80) != 0) ? ((crc << 1) ^ 0x07) : (crc << 1));
            }
            return crc;
        }
    }

    internal sealed class Options
    {
        internal bool Help;
        internal bool List;
        internal bool SelfTest;
        internal uint DeviceIndex;
        internal int Cells = 6;
        internal double? ShuntMilliohms;
        internal string Address = "auto";
        internal string Crc = "auto";
        internal ushort Vid = 0x10C4;
        internal ushort Pid = 0xEA90;

        internal static Options Parse(string[] args)
        {
            Options result = new Options();
            for (int i = 0; i < args.Length; i++)
            {
                string arg = args[i].ToLowerInvariant();
                if (arg == "--help" || arg == "-h") result.Help = true;
                else if (arg == "--list") result.List = true;
                else if (arg == "--self-test") result.SelfTest = true;
                else if (arg == "--device-index") result.DeviceIndex = UInt32.Parse(Next(args, ref i), CultureInfo.InvariantCulture);
                else if (arg == "--cells") result.Cells = Int32.Parse(Next(args, ref i), CultureInfo.InvariantCulture);
                else if (arg == "--shunt-mohm") result.ShuntMilliohms = Double.Parse(Next(args, ref i), CultureInfo.InvariantCulture);
                else if (arg == "--address") result.Address = Next(args, ref i).ToLowerInvariant();
                else if (arg == "--crc") result.Crc = Next(args, ref i).ToLowerInvariant();
                else if (arg == "--vid") result.Vid = ParseUShort(Next(args, ref i));
                else if (arg == "--pid") result.Pid = ParseUShort(Next(args, ref i));
                else throw new ArgumentException("Unknown argument: " + args[i]);
            }
            if (result.Cells < 6 || result.Cells > 10)
                throw new ArgumentOutOfRangeException("--cells", "BQ76930 supports 6..10 series cells.");
            if (result.ShuntMilliohms.HasValue && result.ShuntMilliohms.Value <= 0)
                throw new ArgumentOutOfRangeException("--shunt-mohm", "Shunt resistance must be positive.");
            if (result.Address != "auto" && result.Address != "0x08" && result.Address != "0x18")
                throw new ArgumentException("--address must be auto, 0x08, or 0x18.");
            if (result.Crc != "auto" && result.Crc != "on" && result.Crc != "off")
                throw new ArgumentException("--crc must be auto, on, or off.");
            if (result.Vid == 0 || result.Pid == 0)
                throw new ArgumentException("VID and PID must be non-zero; unfiltered HID access is intentionally disabled.");
            return result;
        }

        private static ushort ParseUShort(string value)
        {
            string normalized = value.StartsWith("0x", StringComparison.OrdinalIgnoreCase)
                ? value.Substring(2)
                : value;
            return UInt16.Parse(normalized, NumberStyles.HexNumber, CultureInfo.InvariantCulture);
        }

        private static string Next(string[] args, ref int index)
        {
            index++;
            if (index >= args.Length) throw new ArgumentException("Missing argument value.");
            return args[index];
        }
    }

    internal static class Program
    {
        private static readonly int[][] CellChannels = new int[][]
        {
            null, null, null, null, null, null,
            new int[] { 1, 2, 5, 6, 7, 10 },
            new int[] { 1, 2, 3, 5, 6, 7, 10 },
            new int[] { 1, 2, 3, 5, 6, 7, 8, 10 },
            new int[] { 1, 2, 3, 4, 5, 6, 7, 8, 10 },
            new int[] { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }
        };

        private static int Main(string[] args)
        {
            try
            {
                Options options = Options.Parse(args);
                if (options.Help || args.Length == 0)
                {
                    PrintHelp();
                    return 0;
                }
                if (options.SelfTest)
                    return SelfTest();
                if (options.List)
                    return ListDevices(options);
                return Diagnose(options);
            }
            catch (DllNotFoundException ex)
            {
                Console.Error.WriteLine("ERROR: SLABHIDtoSMBus.dll or SLABHIDDevice.dll is missing: " + ex.Message);
                return 2;
            }
            catch (BadImageFormatException ex)
            {
                Console.Error.WriteLine("ERROR: DLL architecture mismatch. Use this x86 build with the supplied 32-bit DLLs: " + ex.Message);
                return 3;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("ERROR: " + ex.Message);
                return 1;
            }
        }

        private static int ListDevices(Options options)
        {
            uint count = Cp2112.CountDevices(options.Vid, options.Pid);
            Console.WriteLine("CP2112 candidates VID={0:X4} PID={1:X4}: {2}",
                options.Vid, options.Pid, count);
            for (uint i = 0; i < count; i++)
            {
                string serial;
                try { serial = Cp2112.GetSerial(i, options.Vid, options.Pid); }
                catch { serial = "<serial unavailable>"; }
                Console.WriteLine("  [{0}] {1}", i, serial);
            }
            return 0;
        }

        private static int Diagnose(Options options)
        {
            using (Cp2112 bridge = new Cp2112(options.DeviceIndex, options.Vid, options.Pid))
            {
                byte address;
                bool crc;
                Probe(bridge, options, out address, out crc);
                Bq76930 afe = new Bq76930(bridge, address, crc);
                PrintReport(afe, address, crc, options.Cells, options.ShuntMilliohms);
            }
            return 0;
        }

        private static void Probe(Cp2112 bridge, Options options, out byte address, out bool crc)
        {
            byte[] addresses = options.Address == "auto"
                ? new byte[] { 0x08, 0x18 }
                : new byte[] { Byte.Parse(options.Address.Substring(2), NumberStyles.HexNumber, CultureInfo.InvariantCulture) };

            List<string> failures = new List<string>();
            foreach (byte candidate in addresses)
            {
                try
                {
                    byte writeAddress = (byte)(candidate << 1);
                    if (options.Crc == "on")
                    {
                        Bq76930 crcDevice = new Bq76930(bridge, candidate, true);
                        crcDevice.Read(0x50, 2);
                        address = candidate;
                        crc = true;
                        return;
                    }
                    if (options.Crc == "off")
                    {
                        Bq76930 plainDevice = new Bq76930(bridge, candidate, false);
                        plainDevice.Read(0x50, 2);
                        address = candidate;
                        crc = false;
                        return;
                    }

                    byte[] raw = bridge.ReadAddressed(writeAddress, 0x50, 4);
                    bool detectedCrc = Bq76930.LooksLikeCrcFrame(writeAddress, raw);
                    Bq76930 device = new Bq76930(bridge, candidate, detectedCrc);
                    device.Read(0x00, 1);
                    device.Read(0x59, 1);
                    address = candidate;
                    crc = detectedCrc;
                    return;
                }
                catch (Exception ex)
                {
                    failures.Add(String.Format(CultureInfo.InvariantCulture, "0x{0:X2}: {1}", candidate, ex.Message));
                }
            }
            throw new InvalidOperationException("No bq769x0-compatible response. " + String.Join(" | ", failures.ToArray()));
        }

        private static void PrintReport(Bq76930 afe, byte address, bool crc, int cells, double? shuntMilliohms)
        {
            byte[] config = afe.Read(0x00, 12);
            byte[] cellRaw = afe.Read(0x0C, 20);
            byte[] packRaw = afe.Read(0x2A, 2);
            byte[] tempRaw = afe.Read(0x2C, 4);
            byte[] ccRaw = afe.Read(0x32, 2);
            byte gain1 = afe.Read(0x50, 1)[0];
            sbyte offset = unchecked((sbyte)afe.Read(0x51, 1)[0]);
            byte gain2 = afe.Read(0x59, 1)[0];

            int gainBits = ((gain1 & 0x0C) << 1) | ((gain2 & 0xE0) >> 5);
            int gainMicrovolts = 365 + gainBits;
            ushort packAdc = (ushort)((packRaw[0] << 8) | packRaw[1]);
            double packMillivolts = (4.0 * gainMicrovolts * packAdc / 1000.0) + (cells * offset);

            Console.WriteLine("TB30 / bq76930 read-only diagnostic");
            Console.WriteLine("I2C address: 0x{0:X2} (CP2112 write address 0x{1:X2}), CRC: {2}",
                address, address << 1, crc ? "on" : "off");
            Console.WriteLine("Identification: bq769x0-compatible register map; exact orderable suffix cannot be read from an ID register.");
            Console.WriteLine("Expected pack topology: {0}S, active AFE channels: {1}", cells,
                String.Join(",", Array.ConvertAll(CellChannels[cells], delegate(int value) { return value.ToString(CultureInfo.InvariantCulture); })));
            Console.WriteLine("ADC gain: {0} uV/LSB, offset: {1} mV", gainMicrovolts, offset);
            Console.WriteLine("Pack voltage: {0:F1} mV (raw 0x{1:X4})", packMillivolts, packAdc);

            Console.WriteLine("Cell channels:");
            HashSet<int> active = new HashSet<int>(CellChannels[cells]);
            for (int channel = 1; channel <= 10; channel++)
            {
                int index = (channel - 1) * 2;
                int adc = ((cellRaw[index] & 0x3F) << 8) | cellRaw[index + 1];
                double mv = (adc * gainMicrovolts / 1000.0) + offset;
                Console.WriteLine("  VC{0,2}: raw=0x{1:X4}, {2,7:F1} mV{3}",
                    channel, adc, mv, active.Contains(channel) ? "  [cell]" : "  [short/unused expected]");
            }

            byte sysStat = config[0];
            byte sysCtrl1 = config[4];
            byte sysCtrl2 = config[5];
            Console.WriteLine("SYS_STAT 0x{0:X2}: {1}", sysStat, DecodeStatus(sysStat));
            Console.WriteLine("SYS_CTRL1 0x{0:X2}: ADC={1}, TEMP={2}", sysCtrl1,
                (sysCtrl1 & 0x10) != 0 ? "on" : "off", (sysCtrl1 & 0x08) != 0 ? "external" : "die");
            Console.WriteLine("SYS_CTRL2 0x{0:X2}: CHG={1}, DSG={2}, CC={3}", sysCtrl2,
                (sysCtrl2 & 0x01) != 0 ? "on" : "off", (sysCtrl2 & 0x02) != 0 ? "on" : "off",
                (sysCtrl2 & 0x40) != 0 ? "continuous" : "off/oneshot");
            Console.WriteLine("Protection/config raw: PROTECT1=0x{0:X2}, PROTECT2=0x{1:X2}, PROTECT3=0x{2:X2}, OV=0x{3:X2}, UV=0x{4:X2}, CC_CFG=0x{5:X2}",
                config[6], config[7], config[8], config[9], config[10], config[11]);

            int ts1 = ((tempRaw[0] & 0x3F) << 8) | tempRaw[1];
            int ts2 = ((tempRaw[2] & 0x3F) << 8) | tempRaw[3];
            Console.WriteLine("Temperature ADC raw: TS1=0x{0:X4}, TS2=0x{1:X4}", ts1, ts2);

            short cc = unchecked((short)((ccRaw[0] << 8) | ccRaw[1]));
            double senseMicrovolts = cc * 8.44;
            if (shuntMilliohms.HasValue)
                Console.WriteLine("Coulomb counter: raw={0}, sense={1:F2} uV, current={2:F2} mA (Rshunt={3} mOhm)",
                    cc, senseMicrovolts, senseMicrovolts / shuntMilliohms.Value, shuntMilliohms.Value);
            else
                Console.WriteLine("Coulomb counter: raw={0}, sense={1:F2} uV (use --shunt-mohm to calculate current)",
                    cc, senseMicrovolts);

            Console.WriteLine("No battery register was modified.");
        }

        private static string DecodeStatus(byte value)
        {
            List<string> flags = new List<string>();
            if ((value & 0x80) != 0) flags.Add("CC_READY");
            if ((value & 0x20) != 0) flags.Add("DEVICE_XREADY");
            if ((value & 0x10) != 0) flags.Add("OVRD_ALERT");
            if ((value & 0x08) != 0) flags.Add("UV");
            if ((value & 0x04) != 0) flags.Add("OV");
            if ((value & 0x02) != 0) flags.Add("SCD");
            if ((value & 0x01) != 0) flags.Add("OCD");
            return flags.Count == 0 ? "none" : String.Join(",", flags.ToArray());
        }

        private static int SelfTest()
        {
            byte crc = Bq76930.Crc8(Encoding.ASCII.GetBytes("123456789"));
            if (crc != 0xF4)
            {
                Console.Error.WriteLine("CRC-8 self-test failed: expected F4, got {0:X2}.", crc);
                return 1;
            }
            if (CellChannels[6].Length != 6 || CellChannels[6][5] != 10)
            {
                Console.Error.WriteLine("6S channel-map self-test failed.");
                return 1;
            }
            byte first = 0xA5;
            byte second = 0x5A;
            byte[] frame = new byte[]
            {
                first,
                Bq76930.Crc8(new byte[] { 0x11, first }),
                second,
                Bq76930.Crc8(new byte[] { second })
            };
            if (!Bq76930.LooksLikeCrcFrame(0x10, frame))
            {
                Console.Error.WriteLine("CRC-frame detection self-test failed.");
                return 1;
            }
            Console.WriteLine("Self-test OK: CRC-8/poly-0x07 and BQ76930 6S channel map.");
            return 0;
        }

        private static void PrintHelp()
        {
            Console.WriteLine("Tb30Bq76930Diag - read-only CP2112 diagnostic for a TB30/bq76930 AFE");
            Console.WriteLine();
            Console.WriteLine("Usage:");
            Console.WriteLine("  Tb30Bq76930Diag.exe --list [--vid 10C4 --pid EA90]");
            Console.WriteLine("  Tb30Bq76930Diag.exe --device-index 0 [--address auto|0x08|0x18] [--crc auto|on|off]");
            Console.WriteLine("                            [--cells 6..10] [--shunt-mohm value] [--vid hex --pid hex]");
            Console.WriteLine("  Tb30Bq76930Diag.exe --self-test");
            Console.WriteLine();
            Console.WriteLine("Safety: this build exposes no battery-register write command, no unseal function, and no firmware updater.");
        }
    }
}
