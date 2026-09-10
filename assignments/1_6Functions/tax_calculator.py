def tax_calculator(subtotal, tax_rate=0.06):
    """calculates price with tax

    Args:
        subtotal (float): price of item
        tax_rate (float): tax rate

    Returns:
        float: price with tax
    """
    tax = round(subtotal*(tax_rate), 2)
    total = round(subtotal + tax,2)
    return[subtotal, tax, total]
