# Advanced Mobile Programming

Sembrano, Andrei Stephen C.

INF233 - CTADVMOBL



## Laboratory Discussion-Labact2

ProductService gets product data from the API it sends GET request to the /products endpoint, converts the JSON response using Product.fromJson, and returns a list of Product objects. ProductScreen calls the service and uses FutureBuilder to show loading, errors, or the product list. Each product card displays information like the title, price, and image. Users can also search products or tap a product to view its details and the app uses a mode, view, provider. Models handle data, services communicate with the API, providers manage shared data such as the theme, and screens display the user interface
