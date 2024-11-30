# PySparkDQ - Ad Hoc data quality tool with native pyspark functions

<!--- These are examples. See https://shields.io for others or to customize this set of shields. You might want to include dependencies, project status and licence info here --->
![GitHub repo size](https://img.shields.io/github/repo-size/alexdemag/pysparkdq)
![GitHub License](https://img.shields.io/github/license/alexdemag/pysparkdq)
![Language Count](https://img.shields.io/github/languages/count/alexdemag/pysparkdq)
![Python](https://img.shields.io/badge/python-3.9-red.svg)

This library aims to be an easy to use drop-in tool to perform data quality analysis on scale with PySpark. It does not require you to setup contexts nor make use of configuration files. Just instantiate the class and put some tests on your target dataframe.

## Prerequisites

Before you begin, ensure you have met the following requirements:
<!--- These are just example requirements. Add, duplicate or remove as required --->
* You have access to a Spark/Pyspark enabled environment
* Know what tests you want to run

## Installation

This package is distributed on pypi. To install it just run:


```
pip install pysparkdq
```

## Quickstart

Instantiate the class with the desired spark DataFrame and SparkSession and you're good to go.
```python
from pyspark.sql import SparkSession
import pyspark.sql.functions as f
from pysparkdq import PySparkDQ

spark = SparkSession \
    .builder\
    .appName("PySparkDQ")
    .getOrCreate()

df_test = spark.createDataFrame([
                    {"name": "Alex", "birthday": '1990-03-31'},
                    {"name": "Alice", "birthday": '1990-12-09'},
                    {"name": "Bob", "birthday": '1985-06-12'},
                    {"name": "Cecilia", "birthday": '1990-12-09'},
                    {"name": "Eve", "birthday": '1964-07-22'}]) \
                    .withColumn('birthday', f.col('birthday').cast('date'))


dq = PySparkDQ(spark_session=spark, df=df_test,log_level='INFO')

tests = dq.begin()\
    .values_not_null(colname="name")\
    .values_between(colname='birthday', lower_value='1990-01-01', upper_value='1993-01-01', 
                tolerance=0.5, # You can control tolerances with the optional parameters
                over_under_tolerance='over', 
                inclusive_exclusive='inclusive')\
    .values_custom_dq(test="my custom test", 
        partial=( (f.col('name') == 'Bob') & (f.col('birthday') == '1985-06-12') ))
        # And also write your own tests if you'd like! Custom tests accept a column expression that returns a boolean column.

```
Now that you have your tests, you can do one of the following:

* Get a summary for the test run

```python
test_results = tests.get_summary() # returns a dataframe

test_results.show()
```

| colname   | test            | scope                   |   found |   total |   percentage |   tolerance | over_under_tolerance   | inclusive_exclusive   | pass   |
|:----------|:----------------|:------------------------|--------:|--------:|-------------:|------------:|:-----------------------|:----------------------|:-------|
| name      | values_not_null | null                    |       5 |       5 |          1   |         1   | over                   | inclusive             | True   |
| birthday  | values_between  | 1990-01-01 - 1993-01-01 |       3 |       5 |          0.6 |         0.5 | over                   | inclusive             | True   |
| N/A       | my custom test  | N/A                     |       1 |       5 |          0.2 |         1   | over                   | inclusive             | False  |


* Thrown an exception whenever it has a failed test. in this case it will throw the following error.

```python
tests.evaluate()

AssertionError: Detected failed tests. Count: 1, Tests: [{'colname': 'N/A', 'test': 'my custom test', 'scope': 'N/A'}]
```

* Get a row-based evaluation of your rules. That returns the dataframe with extra folumns indicating how many tests failed and which ones failed per row

```python
row_level_qa = tests.get_row_level_qa() # Returns a dataframe

# Returns two extra columns
# One counts failed tests per row
# Second one is a list<struct> that returns which tests have failed

# ATTENTION! Be careful when comparing this view with the summary. Tests can fail at row level and pass at summary level due to defined tolerances!
row_level_qa.show()

```

| birthday   | name    |   pysparkdq_fail_count | pysparkdq_failed_tests                                                                                                                                                                     |
|:-----------|:--------|-----------------------:|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1990-03-31 | Alex    |                      1 | [Row(colname='N/A', test='my custom test', scope="Column<'((name = Bob) AND (birthday = 1985-06-12))'>")]                                                                                  |
| 1990-12-09 | Alice   |                      1 | [Row(colname='N/A', test='my custom test', scope="Column<'((name = Bob) AND (birthday = 1985-06-12))'>")]                                                                                  |
| 1985-06-12 | Bob     |                      0 | []                                                                                                                                                                                         |
| 1990-12-09 | Cecilia |                      1 | [Row(colname='N/A', test='my custom test', scope="Column<'((name = Bob) AND (birthday = 1985-06-12))'>")]                                                                                  |
| 1964-07-22 | Eve     |                      2 | [Row(colname='birthday', test='values_between', scope='1980-01-01 - 1993-01-01'), Row(colname='N/A', test='my custom test', scope="Column<'((name = Bob) AND (birthday = 1985-06-12))'>")] |


## Contributing
If there's any issues or improvements to be requested fell free to open an issue on the board.