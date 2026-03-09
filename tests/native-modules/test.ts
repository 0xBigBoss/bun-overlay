import { hash, verify } from "argon2";

const password = "test-password";

const run = async (): Promise<void> => {
  const hashed = await hash(password);
  const valid = await verify(hashed, password);

  if (!valid) {
    throw new Error("argon2 verify failed");
  }

  console.log("Native module test passed");
};

run().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Native module test failed: ${message}`);
  process.exit(1);
});
