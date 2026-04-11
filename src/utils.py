def extract_output(result: object) -> str:
    missing = object()
    output = getattr(result, "output", missing)
    if output is not missing:
        return str(output)

    data = getattr(result, "data", missing)
    if data is not missing:
        return str(data)

    return str(result)
