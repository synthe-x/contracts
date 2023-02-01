
import main from "./main";

// and properly handle errors.
main(false).catch((error) => {
	console.error(error);
	process.exitCode = 1;
});