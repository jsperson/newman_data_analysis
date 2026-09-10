
def rating_cleaner(rating):
    """gets numeric portion from web rating string
    Args:
        rating (str): rating string
    Returns:
        int: numeric portion of rating
    """
    return int(rating[0])

def rating_list_cleaner(rating_list):
    """cleans lists of ratings and returns numeric ratings lists

    Args:
        rating_list (list): list of rating strings
    Returns:
        list: list of integer ratings
    """
    numeric_list = []
    for rating in rating_list:
        numeric_rating = rating_cleaner(rating)
        numeric_list.append(numeric_rating)
    return numeric_list
