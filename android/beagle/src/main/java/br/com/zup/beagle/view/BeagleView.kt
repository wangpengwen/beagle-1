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

package br.com.zup.beagle.view

import android.content.Context
import android.view.View
import androidx.lifecycle.Observer
import br.com.zup.beagle.core.ServerDrivenComponent
import br.com.zup.beagle.data.BeagleViewModel
import br.com.zup.beagle.data.ViewState
import br.com.zup.beagle.engine.renderer.RootView
import br.com.zup.beagle.interfaces.OnStateUpdatable
import br.com.zup.beagle.utils.implementsGenericTypeOf

sealed class BeagleViewState {
    data class Error(val throwable: Throwable) : BeagleViewState()
    object LoadStarted : BeagleViewState()
    object LoadFinished : BeagleViewState()
}

interface StateChangedListener {
    fun onStateChanged(state: BeagleViewState)
}

internal class BeagleView(
    context: Context
) : BeagleFlexView(context) {

    var stateChangedListener: StateChangedListener? = null

    private lateinit var rootView: RootView

    private val viewModel by lazy { BeagleViewModel() }

    fun loadView(rootView: RootView, screenRequest: ScreenRequest) {
        loadView(rootView, screenRequest, null)
    }

    fun updateView(rootView: RootView, url: String, view: View) {
        loadView(rootView, ScreenRequest(url), view)
    }

    private fun loadView(rootView: RootView, screenRequest: ScreenRequest, view: View?) {
        this.rootView = rootView
        viewModel.state.observe(rootView.getLifecycleOwner(), Observer<ViewState> { state ->
            handleResponse(state, view)
        })

        viewModel.fetchComponent(screenRequest)
    }

    private fun handleResponse(
        state: ViewState?, view: View?) {
        when (state) {
            is ViewState.Loading -> handleLoading(state.value)
            is ViewState.Error -> handleError(state.throwable)
            is ViewState.DoRender -> renderComponent(state.component, view)
        }
    }

    private fun handleLoading(isLoading: Boolean) {
        val state = if (isLoading) {
            BeagleViewState.LoadStarted
        } else {
            BeagleViewState.LoadFinished
        }
        stateChangedListener?.onStateChanged(state)
    }

    private fun handleError(throwable: Throwable) {
        stateChangedListener?.onStateChanged(BeagleViewState.Error(throwable))
    }

    private fun renderComponent(component: ServerDrivenComponent, view: View? = null) {
        if (view != null) {
            if (component.implementsGenericTypeOf(OnStateUpdatable::class.java, component::class.java)) {
                (component as? OnStateUpdatable<ServerDrivenComponent>)?.onUpdateState(component)
            } else {
                removeView(view)
                addServerDrivenComponent(component, rootView)
            }
        } else {
            removeAllViewsInLayout()
            addServerDrivenComponent(component, rootView)
        }
    }
}
