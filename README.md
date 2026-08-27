# Retail Sales & Customer Analysis

## Project Overview

This project analyzes retail transaction data to understand sales performance, customer behavior, product performance, and geographic patterns.

The analysis is based on the Online Retail dataset, which contains transaction-level data for a UK-based online retailer from December 2010 to December 2011.

## Project Objectives

The main objectives are to:

- analyze overall sales performance and revenue trends;
- understand customer purchasing behavior and customer value;
- identify top-performing products and products with high sales volume;
- analyze product returns;
- compare sales performance across countries.

## Analysis

### Sales Analysis

- Overall sales KPIs
- Sales over time
- Monthly sales performance
- Month-over-month revenue growth
- April vs September performance comparison

### Customer Analysis

- Customer overview
- Monthly customer revenue trend
- Orders per customer
- Customer concentration
- Top 10 customers by revenue

### Product Analysis

- Product sales volume
- Top 10 products by quantity sold
- Product returns
- Revenue by product
- Top 10 products by net revenue
- Product-level aggregation

### Geography Analysis

- Revenue by country
- Top 10 countries by net revenue
- Customers by country
- Top 10 countries by paying customers
- Geographic performance

## Tools

- **Python** — data cleaning, exploratory analysis, calculations, and visualization
- **PostgreSQL / SQL** — database analysis and business queries
- **Power BI** — interactive dashboard and visualization

## Key Findings

- The **United Kingdom** was the main market, generating £8.17M in net revenue and accounting for the majority of paying customers.
- The **top 10% of customers generated 61.45% of total customer revenue**, showing a strong concentration of revenue among high-value customers.
- **65.58% of customers were repeat customers**, while 34.42% made only one purchase.
- **November 2011** had the highest monthly net revenue at approximately **£1.30M**.
- The highest monthly ARPPU was **£1,012.30 in September 2011**.
- The **top 10 customers generated 17.31% of total gross revenue**.

## Data Source

The dataset is based on the **Online Retail** dataset from the UCI Machine Learning Repository.

Original source: [UCI Machine Learning Repository — Online Retail](https://uci-ics-mlr-prod.aws.uci.edu/dataset/352/online%2Bretail)

The dataset was obtained through Kaggle.

## Project Structure

```text
retail-sales-customer-analysis/
│
├── README.md
├── retail_analysis.sql
├── retail_sales_customer_analysis.ipynb
└── retail_analysis_result.xlsx
