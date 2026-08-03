import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";

const outputDir = path.resolve("v400-calibration", "max-flow");
const outputFile = path.join(outputDir, "V400_PETG_MaxFlow_7-15_step0.5_230C.gcode");

const filamentDiameter = 1.75;
const filamentArea = Math.PI * filamentDiameter * filamentDiameter / 4;
const layerHeight = 0.20;
const firstLayerHeight = 0.22;
const lineWidth = 0.45;
const firstLayerWidth = 0.50;
const towerHalfSize = 20.0;
const baseLayers = 5;
const minFlow = 7.0;
const maxFlow = 15.0;
const flowStep = 0.5;
const layersPerBand = 5; // 1.0 mm per flow band
const bands = Math.round((maxFlow - minFlow) / flowStep) + 1;

const gcode = [];
const emit = (line = "") => gcode.push(line);
const fmt = (value, digits = 3) => Number(value).toFixed(digits);
const extrusionFor = (length, width, height) => length * width * height / filamentArea;

function squareLoop(halfSize, z, width, height, speedMmS, comment) {
  const side = halfSize * 2;
  const e = extrusionFor(side, width, height);
  emit(`; ${comment}`);
  emit(`G0 X-${fmt(halfSize)} Y-${fmt(halfSize)} F12000`);
  emit(`G1 X${fmt(halfSize)} Y-${fmt(halfSize)} E${fmt(e, 5)} F${fmt(speedMmS * 60, 0)}`);
  emit(`G1 X${fmt(halfSize)} Y${fmt(halfSize)} E${fmt(e, 5)}`);
  emit(`G1 X-${fmt(halfSize)} Y${fmt(halfSize)} E${fmt(e, 5)}`);
  emit(`G1 X-${fmt(halfSize)} Y-${fmt(halfSize)} E${fmt(e, 5)}`);
}

emit("; FLSUN V400 PETG MAX VOLUMETRIC FLOW CALIBRATION");
emit("; Nozzle: 0.4 mm | Filament: PETG 1.75 mm");
emit("; Flow range: 7.0 to 15.0 mm^3/s | Step: 0.5 mm^3/s per 1.0 mm");
emit("; Tower: 40 x 40 mm single wall | Layer: 0.20 mm | Line width: 0.45 mm");
emit("; Stop the print when extrusion first becomes rough, matte, sparse, or starts skipping.");
emit("; Recommended result: last clean flow value minus 10 percent.");
emit(";");
emit("M140 S80 ; begin heating bed");
emit("M104 S150 ; anti-ooze homing temperature");
emit("M106 S0");
emit("G90");
emit("M83");
emit("PRINT_START ; G28 and load saved default bed mesh");
emit("M190 S80 ; wait for PETG bed temperature");
emit("M109 S230 ; wait for PETG nozzle temperature");
emit("SET_VELOCITY_LIMIT VELOCITY=400 ACCEL=3500 ACCEL_TO_DECEL=2500");
emit("SET_VELOCITY_LIMIT SQUARE_CORNER_VELOCITY=5");
emit("SET_PRESSURE_ADVANCE ADVANCE=0.020 SMOOTH_TIME=0.040");
emit("G92 E0");
emit("G0 Z5 F1800");
emit("G0 X-50 Y-35 F12000");
emit(`G0 Z${fmt(firstLayerHeight)} F900`);
emit(`G1 X50 Y-35 E${fmt(extrusionFor(100, firstLayerWidth, firstLayerHeight), 5)} F1500 ; prime line`);
emit("G1 E-0.8 F1800");
emit("G0 X-22.5 Y-22.5 F12000");
emit("G1 E0.8 F1800");

for (const halfSize of [22.5, 22.0, 21.5, 21.0]) {
  squareLoop(halfSize, firstLayerHeight, firstLayerWidth, firstLayerHeight, 25, `first-layer brim ${fmt(halfSize * 2, 1)} mm`);
}

for (let layer = 0; layer < baseLayers; layer += 1) {
  const z = firstLayerHeight + layer * layerHeight;
  emit(`;LAYER:${layer}`);
  if (layer > 0) emit(`G0 Z${fmt(z)} F1200`);
  squareLoop(towerHalfSize, z, lineWidth, layer === 0 ? firstLayerHeight : layerHeight, layer === 0 ? 25 : 40, `base outer wall ${layer + 1}/${baseLayers}`);
  squareLoop(towerHalfSize - lineWidth, z, lineWidth, layer === 0 ? firstLayerHeight : layerHeight, layer === 0 ? 25 : 40, `base inner wall ${layer + 1}/${baseLayers}`);
}

emit("M140 S80 ; normal PETG bed temperature after base");
emit("M106 S64 ; 25 percent part cooling");

let layerNumber = baseLayers;
for (let band = 0; band < bands; band += 1) {
  const flow = minFlow + band * flowStep;
  const speed = flow / (lineWidth * layerHeight);
  emit(`;FLOW_BAND:${band} Q=${fmt(flow, 1)}mm3/s SPEED=${fmt(speed, 1)}mm/s`);
  emit(`M117 Flow ${fmt(flow, 1)} mm3s`);
  for (let bandLayer = 0; bandLayer < layersPerBand; bandLayer += 1) {
    const z = firstLayerHeight + layerNumber * layerHeight;
    emit(`;LAYER:${layerNumber}`);
    emit(`;Q:${fmt(flow, 1)}`);
    emit(`G0 Z${fmt(z)} F1200`);
    squareLoop(towerHalfSize, z, lineWidth, layerHeight, speed, `calibration band ${band + 1}/${bands}, layer ${bandLayer + 1}/${layersPerBand}`);
    layerNumber += 1;
  }
}

emit("M400");
emit("G92 E0");
emit("G1 E-2 F1800");
emit("PRINT_END ; heaters off, fan off, and mandatory G28");
emit("M117 Max flow test complete");
emit("; Keep delta steppers enabled so the effector cannot drop.");

await mkdir(outputDir, { recursive: true });
await writeFile(outputFile, `${gcode.join("\n")}\n`, "utf8");

console.log(JSON.stringify({
  outputFile,
  layers: layerNumber,
  finalZ: firstLayerHeight + (layerNumber - 1) * layerHeight,
  bands,
  maxExtrusionSpeed: maxFlow / (lineWidth * layerHeight),
  lineCount: gcode.length,
}, null, 2));
