
import main from "./main";

// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});