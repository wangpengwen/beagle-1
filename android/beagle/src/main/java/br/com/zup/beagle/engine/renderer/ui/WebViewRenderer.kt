/*
 * Copyright 2020 ZUP IT SERVICOS EM TECNOLOGIA E INOVACAO SA
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package br.com.zup.beagle.engine.renderer.ui

import android.content.Context
import android.graphics.Bitmap
import android.net.http.SslError
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebViewClient
import br.com.zup.beagle.engine.renderer.RootView
import br.com.zup.beagle.engine.renderer.UIViewRenderer
import br.com.zup.beagle.view.BeagleActivity
import br.com.zup.beagle.view.ServerDrivenState
import br.com.zup.beagle.view.ViewFactory
import br.com.zup.beagle.widget.ui.WebView

internal class WebViewRenderer(
    override val component: WebView,
    private val viewFactory: ViewFactory = ViewFactory()
) : UIViewRenderer<WebView>() {

    override fun buildView(rootView: RootView) = viewFactory.makeWebView(rootView.getContext()).apply {
        webViewClient = BeagleWebViewClient(rootView.getContext())
        loadUrl(component.url)
    }

    class BeagleWebViewClient(val context: Context): WebViewClient() {

        override fun onPageFinished(view: android.webkit.WebView?, url: String?) {
            notify(loading = false)
        }

        override fun onPageStarted(
            view: android.webkit.WebView?,
            url: String?,
            favicon: Bitmap?
        ) {
            notify(loading = true)
        }

        override fun onReceivedSslError(
            view: android.webkit.WebView?,
            handler: SslErrorHandler?,
            error: SslError?
        ) {
            handler?.proceed()
        }

        override fun onReceivedError(
            view: android.webkit.WebView?,
            request: WebResourceRequest?,
            error: WebResourceError?
        ) {
            super.onReceivedError(view, request, error)
            val throwable = Error("$error")
            notify(state = ServerDrivenState.Error(throwable))
        }

        fun notify(loading: Boolean) {
            notify(state = ServerDrivenState.Loading(loading))
        }

        fun notify(state: ServerDrivenState) {
            (context as? BeagleActivity)?.onServerDrivenContainerStateChanged(state)
        }
    }
}
