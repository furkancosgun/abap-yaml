import { rmSync } from "fs";

rmSync("output", { recursive: true, force: true });
