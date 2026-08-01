/**
 * pi-file-snapshots entry point.
 *
 * pi auto-discovers `index.ts` in an extension subdirectory; this file just
 * re-exports the factory from `src/extension.ts`.
 */

export { default } from "./src/extension.ts";
