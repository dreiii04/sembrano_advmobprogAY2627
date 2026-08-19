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

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
