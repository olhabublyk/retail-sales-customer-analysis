## How to Run

### Prerequisites
- A Google account (the notebook is written for Google Colab), or Python 3.9+ with Jupyter if you run it locally
- Python libraries: `pandas`, `matplotlib`, `openpyxl`
- PostgreSQL and a SQL client (pgAdmin, DBeaver, or `psql`)
- Power BI Desktop (Windows) to open the dashboard

### 1. Download the dataset
Download the file from [Kaggle](https://www.kaggle.com/datasets/jihyeseo/online-retail-data-set-from-uci-ml-repo) 
(or the original from [UCI](https://archive.ics.uci.edu/dataset/352/online-retail)) and save it as `dataset.xlsx`.

### 2. Run the Python notebook
The notebook cleans the data, runs the exploratory analysis, builds the charts, and exports the results.

**In Google Colab (as written):**
1. Create a Drive folder named `Retail Sales & Customer Analysis` and upload `dataset.xlsx` into it.
2. Open `retail_sales_customer_analysis.ipynb` in Colab and run all cells (**Runtime → Run all**). Allow access to Google Drive when prompted.
3. The final cell creates `retail_analysis_results.xlsx`. Download it from the Colab file panel.

**Locally:**
1. Install the libraries: `pip install pandas matplotlib openpyxl jupyter`
2. In the first code cell, remove the two `google.colab` lines and set `file_path` to the local path of `dataset.xlsx`.
3. Run all cells. The results file is saved in the notebook's working folder.

### 3. Run the SQL analysis (PostgreSQL)
1. Create a database, for example `CREATE DATABASE retail_analysis;`
2. Run **Section 1** of `02-sql/retail_analysis.sql`, up to the `CREATE TABLE retail_sales_raw` statement.
3. Load the raw data into `retail_sales_raw`. Export `dataset.xlsx` to CSV with the columns in this order: `invoice_no, stock_code, description, quantity, invoice_date, unit_price, customer_id, country`. Then import it with pgAdmin (**Import/Export Data**) or:
```sql
   \copy retail_sales_raw FROM 'dataset.csv' WITH (FORMAT csv, HEADER true)
```
   `customer_id` must be whole numbers (for example `17850`, not `17850.0`).
4. Run the rest of the script in order. The sections are:
   1. Data preparation: creates `retail_sales`, removes duplicates, and calculates `revenue`
   2. Sales overview: KPIs, AOV, ARPPU, gross revenue, returns, and net revenue
   3. Sales over time: monthly performance, month-over-month growth, and April vs September 2011
   4. Customer analysis: customer metrics, top 10% revenue share, and top 10 customers
   5. Product analysis: top products by quantity, returns, and net revenue
   6. Geography analysis: top countries by net revenue and by paying customers

### 4. Open the dashboard
Open `04-power_bi/retail_sales_customer_analysis.pbix` in Power BI Desktop. [Add one line on the data source, e.g. "The dashboard reads from `retail_analysis_results.xlsx`; if Power BI shows a data source error, update the file path in **Transform data → Data source settings**."]

### Results
Query and notebook outputs are saved in `03-results/retail_analysis_results.xlsx`.
