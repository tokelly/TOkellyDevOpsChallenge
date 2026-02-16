# Log Analysis challenge

Hi! Welcome to my Singular Systems Dev-Ops Challenge! This project automates the process of downloading, parsing, and reporting on monthly application logs. The result is a clean, interactive HTML report summarising log activity and trends.

---

## Setup & deployment instructions

### 1. Prerequisites

- **Windows OS** (recommended)
- **PowerShell 5.1+** (pre-installed on most Windows systems)
- **Internet connection** (to download log files)

---

### 2. Clone or download the repository

Download or clone this repository to your local machine:

```sh
git clone https://github.com/tokelly/TOkellyDevOpsChallenge.git
cd TOkellyDevOpsChallenge
```
Or simply download and extract the ZIP file.

---

### 3. Run the script

Open PowerShell, navigate to the project directory, and execute:

```powershell
.\Script.ps1
```

The script will:
- Download the latest log index and log files.
- Parse and analyse the logs.
- Generate a detailed HTML report in the `report/` folder.

---

### 4. View the report

After the script completes, open the report:

- Navigate to the `report` directory.
- Open `index.html` in your web browser to view the interactive report.

---

## 🛠️ Troubleshooting

- **Execution policy error?**  
  If you see a policy error, run:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
  Then re-run the script.

- **Internet issues?**  
  Ensure you have a stable connection to download the log files.

---

## 📁 Project structure

```
.
├── Script.ps1
├── index.txt
├── logs/
│   └── ... (downloaded log files)
├── report/
│   ├── index.html
│   └── report.json
└── README.md
```

---
## 🧠 Technical challenges & reflections

### Challenges faced

- **Incremental Calculations:** Calculating month-over-month percentage changes required careful handling of edge cases, such as months with zero warnings or errors, to avoid division by zero and misleading results.
- **Automation & Reporting:** Generating a clean, readable HTML report from raw data involved balancing automation with clarity, ensuring the output was both informative and visually appealing.

### Problem-solving approach

- I started by breaking down the requirements into smaller tasks: downloading files, parsing logs, aggregating statistics, and generating reports.
- For each step, I tested with sample data and added error handling to make the script resilient.
- I iteratively improved the script, refactoring for readability and maintainability, and validated the output at each stage.

## Deployment

This project uses **GitHub Actions** to automatically deploy the static report to [GitHub Pages](https://pages.github.com/):

- On every push to the `main` branch, a workflow runs in `.github/workflows/deploy.yaml`.
- The workflow checks out the repository, runs the PowerShell script to generate the `report` folder, and then publishes the contents of `report/` to GitHub Pages.
- No manual deployment is needed—just push your changes and the site updates automatically!

## Running the Web App in Docker

1. **Build the Docker image:**
   ```sh
   docker build -t log-report-app .
   ```

2. **Run the container and expose port 8080:**
   ```sh
   docker run -d --name log-report-app -p 8080:80 log-report-app
   ```

3. **Open your browser and visit:**
   ```
   http://localhost:8080
   ```
   You should see the web app (index.html) served from the container.

4. **To stop and remove the container:**
   ```sh
   docker stop log-report-app
   docker rm log-report-app
   ```


### How I would improve the project

- **Unit Tests:** Add automated tests for each function to catch edge cases and regressions.
- **Configurable Inputs:** Allow users to specify custom log sources or report formats via command-line arguments.
- **Visualisation:** Enhance the HTML report with charts or graphs for better data visualization.
- **Performance:** Optimise for large datasets, possibly by streaming files instead of loading them entirely into memory.
- **Cross-Platform Support:** Ensure compatibility with Linux/macOS PowerShell environments.

---

Reflecting on the project, I enjoyed the challenge of turning raw log data into actionable insights and would welcome the opportunity to further enhance the solution with more advanced features and polish.
