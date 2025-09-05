import json
import re
import pandas as pd

## Fetch the data Kaggle here: https://www.kaggle.com/datasets/Cornell-University/arxiv
## Make sure to download the JSON snapshot file, and have it available in the working directory

## These are old subcategory tags, replace with their current tags
subcategory_replacement_map = {
    "adap-org": "nlin.AO",
    "alg-geom": "math.AG",
    "astro-ph": "astro-ph.GEN",
    "chao-dyn": "nlin.CD",
    "cond-mat": "cond-mat.GEN",
    "dg-ga": "math.DG",
    "funct-an": "math.FA",
    "patt-sol": "nlin.PS",
    "q-alg": "math.QA",
    "q-bio": "q-bio.GEN",
    "solv-int": "nlin.SI"
}

## Assuming you've downloaded the snapshot from Kaggle in JSON format
def get_metadata():
    with open("arxiv-metadata-oai-snapshot.json", "r") as f:
        for line in f:
            yield line

## ...
rows = []

## ...
metadata = get_metadata()

## ...
for paper in metadata:
    paper_dict = json.loads(paper)
    ref = paper_dict.get("journal-ref")
    try:
        year_published = int(re.search(r"\((\d{4})\)", ref).group(1))
        if 2000 < year_published <= 2025:
            rows.append({
                "arxiv_id": paper_dict["id"],
                "authors": len(paper_dict["authors_parsed"]),
                "year": year_published,
                "subcategory": paper_dict.get("categories"),
                "versions": len(paper_dict["versions"]),
                "update_date": paper_dict["update_date"]
                })
    except:
        pass

## Convert list of dictionaries to DataFrame
data = pd.DataFrame(rows)

## Count the number of categories in each
data["subcategory"] = data["subcategory"].str.split(" ")

## ...
data_long = data.explode("subcategory").reset_index(drop=False)

## ...
data_long["subcategory"] = data_long["subcategory"].replace(subcategory_replacement_map)

## ...
data_long.to_parquet("arxiv.parquet")
# data.to_parquet("arxiv.parquet")
