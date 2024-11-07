### big data
- polars (https://realpython.com/polars-python/)
```
import numpy as np
import polars as pl
num_rows = 5000
rng = np.random.default_rng(seed=7)
data = {
     "sqft": rng.exponential(scale=1000, size=num_rows),
     "year": rng.integers(low=1995, high=2023, size=num_rows),
     "building": rng.choice(["A", "B", "C"], size=num_rows),
     "price": rng.normal(loc=100_000, scale=50_000, size=num_rows)
}
buildings = pl.DataFrame(data)
buildings
buildings.schema
buildings.head()
buildings.describe()
buildings.select("sqft")
buildings.select(pl.col("sqft"))
buildings.select(pl.col("sqft").sort() / 1000)
after_2015 = buildings.filter(pl.col("year") > 2015)
after_2015.shape
after_2015.select(pl.col("year").min())
```