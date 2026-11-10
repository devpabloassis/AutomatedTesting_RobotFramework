package com.foodmarketplace.app.model

import kotlinx.serialization.Serializable

// Data returned by the Food Marketplace API (see docs/API_ENDPOINTS.md).
// Monetary values are integers in cents.

@Serializable
data class ProductOption(val id: String, val label: String, val priceCents: Int)

@Serializable
data class Product(val id: String, val name: String, val options: List<ProductOption>)

@Serializable
data class Company(
    val id: String,
    val name: String,
    val description: String,
    val products: List<Product> = emptyList(),
)

@Serializable
data class CartItem(
    val id: String,
    val companyId: String,
    val companyName: String,
    val productId: String,
    val productName: String,
    val optionId: String,
    val optionLabel: String,
    val unitPriceCents: Int,
    val quantity: Int,
    val subtotalCents: Int,
)

@Serializable
data class Cart(
    val username: String,
    val items: List<CartItem>,
    val companyIds: List<String>,
    val hasMixedCompanies: Boolean,
    val totalItems: Int,
    val totalCents: Int,
)

@Serializable
data class User(val username: String, val createdAt: String)

@Serializable
data class Payment(val status: String, val totalCents: Int, val message: String)

@Serializable
data class ApiErrorBody(val code: String, val message: String)
