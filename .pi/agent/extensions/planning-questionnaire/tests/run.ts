/**
 * Test entry: import every `*.test.ts` suite so all of their `node:test`
 * registrations run together. Run with:
 *
 *   jiti tests/run.ts        # with NODE_PATH pointed at the pi monorepo
 *
 * or via the package `test` script (see package.json).
 */
import "./types.test.ts"
import "./session.test.ts"
import "./clarify.test.ts"
import "./tool.test.ts"
import "./ui.test.ts"
