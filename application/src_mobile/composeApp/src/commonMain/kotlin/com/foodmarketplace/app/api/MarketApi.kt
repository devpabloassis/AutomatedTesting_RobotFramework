package com.foodmarketplace.app.api

import com.foodmarketplace.app.model.ApiErrorBody
import com.foodmarketplace.app.model.Cart
import com.foodmarketplace.app.model.Company
import com.foodmarketplace.app.model.Payment
import com.foodmarketplace.app.model.User
import io.ktor.client.HttpClient
import io.ktor.client.request.request
import io.ktor.client.request.setBody
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpMethod
import io.ktor.http.content.TextContent
import io.ktor.http.encodeURLPathPart
import io.ktor.http.isSuccess
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

/** Error returned by the API, in the `{ "code": "...", "message": "..." }` format. */
class ApiException(val status: Int, val code: String, override val message: String) : Exception(message)

/**
 * Client of the Food Marketplace REST API.
 * The base URL is read on every request, so it can be changed at runtime through a deep link.
 */
class MarketApi(private val client: HttpClient, private val baseUrl: () -> String) {

    // Unknown fields are ignored, like the web UI does. That is why BUG-04 (an extra field in
    // GET /companies) is only detected by the API contract tests.
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun login(username: String, password: String): User = json.decodeFromString(
        send(
            HttpMethod.Post, "/login",
            buildJsonObject {
                put("username", username)
                put("password", password)
            },
        ),
    )

    suspend fun companies(): List<Company> = json.decodeFromString(send(HttpMethod.Get, "/companies"))

    suspend fun company(companyId: String): Company =
        json.decodeFromString(send(HttpMethod.Get, "/companies/${companyId.encodeURLPathPart()}"))

    suspend fun cart(username: String): Cart = json.decodeFromString(send(HttpMethod.Get, cartPath(username)))

    suspend fun addItem(
        username: String,
        companyId: String,
        productId: String,
        optionId: String,
        replaceCart: Boolean = false,
    ): Cart = json.decodeFromString(
        send(
            HttpMethod.Post, "${cartPath(username)}/items",
            buildJsonObject {
                put("companyId", companyId)
                put("productId", productId)
                put("optionId", optionId)
                put("quantity", 1)
                if (replaceCart) put("replaceCart", true)
            },
        ),
    )

    /** The quantity is sent as typed (integer, decimal or null), so the API validates its domain. */
    suspend fun updateItem(username: String, itemId: String, quantity: JsonElement): Cart = json.decodeFromString(
        send(
            HttpMethod.Patch, "${cartPath(username)}/items/${itemId.encodeURLPathPart()}",
            buildJsonObject { put("quantity", quantity) },
        ),
    )

    suspend fun deleteItem(username: String, itemId: String): Cart =
        json.decodeFromString(send(HttpMethod.Delete, "${cartPath(username)}/items/${itemId.encodeURLPathPart()}"))

    suspend fun checkout(username: String) {
        send(HttpMethod.Post, "${cartPath(username)}/checkout")
    }

    suspend fun pay(username: String): Payment =
        json.decodeFromString(send(HttpMethod.Post, "${cartPath(username)}/pay"))

    private fun cartPath(username: String) = "/users/${username.encodeURLPathPart()}/cart"

    private suspend fun send(method: HttpMethod, path: String, body: JsonElement? = null): String {
        val response = try {
            client.request(baseUrl().trimEnd('/') + path) {
                this.method = method
                if (body != null) setBody(TextContent(body.toString(), ContentType.Application.Json))
            }
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            throw ApiException(0, "NETWORK_ERROR", "Unable to reach the server.")
        }
        val text = response.bodyAsText()
        if (!response.status.isSuccess()) {
            val error = runCatching { json.decodeFromString<ApiErrorBody>(text) }.getOrNull()
            throw ApiException(
                response.status.value,
                error?.code ?: "UNEXPECTED_RESPONSE",
                error?.message ?: "Unexpected server response.",
            )
        }
        return text
    }
}

/**
 * Converts the text typed in the quantity field into JSON, the same way the web version does
 * with `Number(value)`: empty text becomes 0, numbers are kept and anything else becomes null.
 * The API is the one that validates the domain (integer from 1 to 99).
 */
fun quantityToJson(text: String): JsonElement {
    val value = text.trim()
    if (value.isEmpty()) return JsonPrimitive(0)
    value.toLongOrNull()?.let { return JsonPrimitive(it) }
    value.toDoubleOrNull()?.let { return JsonPrimitive(it) }
    return JsonNull
}
