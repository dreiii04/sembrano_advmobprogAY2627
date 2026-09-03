# Sembrano, Andrei Stephen C. CCIT

## INF233

## CTADVMOBL Advanced Mobile Programming

## Lab Activity Instance

A new Flutter project.

## Getting Started

## Laboratory Discussion

### Lab 1 - Theme (Dark/Light Mode)

`setState` is used when the data belongs to only one widget. Provider is used when the data belongs to multiple widgets.

### Lab 2 - Product API

`ProductService` gets product data from the API. It sends a GET request to the `/products` endpoint, converts the JSON response using `Product.fromJson`, and returns a list of `Product` objects.

`ProductScreen` calls the service and uses `FutureBuilder` to show loading, errors, or the product list. Each product card displays information such as the title, price, and image. Users can also search for products or tap a product to view its details.

The app uses a model-view-provider structure. Models handle data, services communicate with the API, providers manage shared data such as the theme, and screens display the user interface.

### Lab 3 - Cart API

The cart model, service, and screen work together to get and display cart data from the API. The `Cart` and `CartProduct` models handle the cart data, while `CartService` sends requests to the API. `CartScreen` uses `FutureBuilder` to show the cart, loading screen, error message, or empty-cart message.The app follows a model-service-screen pattern, while Provider is used for shared data like the theme. This setup makes the code more organized and easier to understand and maintain. To get the cart, `CartService.getCartByUser` sends a GET request to `/carts/user/5`. The returned JSON data is converted into a `Cart` object and displayed on `CartScreen`. If there is no cart, an empty-cart message is shown, and if an error happens, the user can retry the request.

### Lab 4 - User Authentication & Profile

In this activity, I used the Model-Service-Screen pattern where my user service calls the API, saves the login data into SharedPreferences, and converts it into a User model so the profile screen can display everything cleanly. From there, the cart screen grabs that saved user ID to dynamically fetch and display the specific cart items belonging to the logged-in user instead of relying on a hardcoded number. Connecting them this way really helped me see how data flows across the app, making the whole login and shopping experience feel connected and seamless.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
