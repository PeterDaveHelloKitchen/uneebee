defmodule UneebeeWeb.Components.Dashboard.OptionList do
  @moduledoc false
  use UneebeeWeb, :live_component

  alias Uneebee.Content
  alias Uneebee.Content.Course
  alias Uneebee.Content.Lesson
  alias Uneebee.Content.LessonStep
  alias Uneebee.Content.StepOption

  attr :action, :atom, default: nil
  attr :course, Course, required: true
  attr :lesson, Lesson, required: true
  attr :option_id, :string, default: nil
  attr :step, LessonStep, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <ul class="mt-8 space-y-2">
        <li :for={option <- @step.options} class="flex items-center gap-2">
          <.link id={"option-#{option.id}-image-link"} patch={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}/o/#{option.id}/image"}>
            <.avatar src={option.image} alt={option.title} />
          </.link>

          <.link
            patch={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}/o/#{option.id}"}
            class={[
              "w-max truncate rounded-2xl border px-2 py-1",
              option.correct? && "bg-success-light3x text-success-dark2x border-success-dark2x",
              not option.correct? && "border-gray-light"
            ]}
          >
            <%= option.title %>
          </.link>

          <.icon_button
            icon="tabler-x"
            color={:alert_light}
            size={:sm}
            role="button"
            label={dgettext("orgs", "Delete option")}
            data-confirm={gettext("Are you sure?")}
            phx-click="delete-option"
            phx-value-option-id={option.id}
            phx-target={@myself}
          />
        </li>
      </ul>

      <.modal :if={@action == :option} show id="edit-option-modal" on_cancel={JS.patch(~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}")}>
        <.simple_form
          for={@option_form}
          title={dgettext("orgs", "Update option")}
          id="option-form"
          phx-change="validate-option"
          phx-target={@myself}
          phx-submit="update-option"
          unstyled
        >
          <.input type="text" field={@option_form[:title]} label={dgettext("orgs", "Option title")} required />

          <.input
            type="text"
            field={@option_form[:feedback]}
            label={dgettext("orgs", "Option feedback")}
            helper={dgettext("orgs", "Feedback message displayed after a user answers this question. You can provide some additional context on why this is wrong or correct.")}
          />

          <.input
            type="checkbox"
            field={@option_form[:correct?]}
            label={dgettext("orgs", "Is correct?")}
            helper={dgettext("orgs", "Check this option if this is the correct answer.")}
          />

          <:actions>
            <.button type="submit"><%= gettext("Save") %></.button>
          </:actions>
        </.simple_form>
      </.modal>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket = socket |> assign(assigns) |> get_option(assigns.option_id)

    {:ok, socket}
  end

  defp get_option(socket, nil), do: socket

  defp get_option(socket, option_id) do
    option = Content.get_step_option!(option_id)
    changeset = Content.change_step_option(option)
    socket |> assign(:selected_option, option) |> assign(:option_form, to_form(changeset))
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate-option", %{"step_option" => step_option_params}, socket) do
    changeset = %StepOption{} |> Content.change_step_option(step_option_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, option_form: to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("update-option", %{"step_option" => option_params}, socket) do
    %{course: course, lesson: lesson, selected_option: option, step: step} = socket.assigns

    case Content.update_step_option(option, option_params) do
      {:ok, _option} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, _changeset} ->
        {:noreply, put_flash!(socket, :error, dgettext("orgs", "Could not update option!"))}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete-option", params, socket) do
    %{course: course, lesson: lesson, step: step} = socket.assigns
    option_id = String.to_integer(params["option-id"])

    case Content.delete_step_option(option_id) do
      {:ok, _option} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, _changeset} ->
        {:noreply, put_flash!(socket, :error, dgettext("orgs", "Could not delete option!"))}
    end
  end
end