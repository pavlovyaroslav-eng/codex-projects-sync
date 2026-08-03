#!/usr/bin/env python3
import argparse
from pathlib import Path

import torch
from safetensors.torch import save_file


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert an official Meta SAM 2 checkpoint to safetensors")
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--half", action="store_true")
    args = parser.parse_args()

    loaded = torch.load(args.source, map_location="cpu", weights_only=True)
    state = loaded.get("model", loaded) if isinstance(loaded, dict) else loaded
    converted = {}
    for name, tensor in state.items():
        if not isinstance(tensor, torch.Tensor):
            continue
        tensor = tensor.detach().contiguous()
        if args.half and tensor.is_floating_point():
            tensor = tensor.half()
        converted[name] = tensor
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    save_file(converted, args.destination, metadata={"source": "official Meta SAM 2.1 checkpoint"})
    print(f"Converted {len(converted)} tensors to {args.destination}")


if __name__ == "__main__":
    main()

