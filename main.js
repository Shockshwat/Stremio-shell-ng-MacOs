const { spawn, spawnSync } = require("child_process");
const { app, BrowserWindow, screen } = require("electron");
const path = require("path");

const arch = process.arch;
const serviceName =
	arch === "arm64" ? "StremioService.arm.app" : "StremioService.x64.app";

const servicePath = path.join(
	__dirname,
	`Stremio_Runtime/${serviceName}/Contents/MacOS/stremio-service`
);

const child = spawn(servicePath, [], {
	shell: true,
});

child.stdout.on("data", (data) => {
	console.log(`stdout: ${data}`);
});

child.stderr.on("data", (data) => {
	console.error(`stderr: ${data}`);
});

child.on("error", (err) => {
	console.error(`Failed to start subprocess: ${err}`);
});

child.on("close", (code) => {
	console.log(`child process exited with code ${code}`);
});

const CreateWindow = () => {
	const { width, height } = screen.getPrimaryDisplay().workAreaSize;
	const win = new BrowserWindow({
		width: Math.round(width * 0.8),
		height: Math.round(height * 0.8),
		webPreferences: {
			nodeIntegration: true,
		},
		icon: path.join(__dirname, "img/stremio.icns"),
	});
	win.loadURL("https://web.stremio.com");
};

app.whenReady().then(CreateWindow);

app.on("before-quit", () => {
	child.kill();
	spawnSync("pkill", ["-f", "stremio-runtime"]);
});
