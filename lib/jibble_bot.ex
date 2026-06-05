defmodule JibbleBot do
  @chromedriver_url "http://localhost:9515"
  @brave_binary "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"

  def start_chromedriver do
    Port.open({:spawn, "chromedriver --port=9515"}, [:binary])
    IO.puts("Chrome driver started")
    wait(5000)
  end

  def stop_chromedriver do
    System.cmd("pkill", ["-f", "chromedriver"])
    IO.puts("Chromedriver stopped")
  end

  def create_session do
    body = Jason.encode!(%{
      "capabilities" => %{
        "alwaysMatch" => %{
          "browserName" => "chrome",
          "goog:chromeOptions" => %{
            "binary" => @brave_binary,
            "args" => ["--no-sandbox", "--disable-dev-shm-usage"]
          }
        }
      }
    })

    case HTTPoison.post("#{@chromedriver_url}/session", body, [{"Content-Type", "application/json"}]) do
      {:ok, %{status_code: 200, body: response_body}} ->
        {:ok, decoded} = Jason.decode(response_body)
        session_id = decoded["value"]["sessionId"]
        IO.puts("Session created: #{session_id}")
        {:ok, session_id}

      {:error, reason} ->
        IO.puts("Failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def close_session(session_id) do
    HTTPoison.delete("#{@chromedriver_url}/session/#{session_id}")
    IO.puts("Session closed")
  end

  def navigate(session_id, url) do
    body = Jason.encode!(%{"url" => url})
    case HTTPoison.post(
      "#{@chromedriver_url}/session/#{session_id}/url",
      body,
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, %{status_code: 200}} ->
        IO.puts("Navigated to #{url}")
        {:ok, session_id}

      {:error, reason} ->
        IO.puts("Failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def find_element(session_id, css_selector) do
    body = Jason.encode!(%{
      "using" => "css selector",
      "value" => css_selector
    })

    case HTTPoison.post(
      "#{@chromedriver_url}/session/#{session_id}/element",
      body,
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, %{status_code: 200, body: response_body}} ->
        {:ok, decoded} = Jason.decode(response_body)
        element_id = decoded["value"]["element-6066-11e4-a52e-4f735466cecf"]
        IO.puts("Found element: #{element_id}")
        {:ok, element_id}

      {:error, reason} ->
        IO.puts("Failed to find element: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def type_text(session_id, element_id, text) do
    body = Jason.encode!(%{"text" => text})
    case HTTPoison.post(
      "#{@chromedriver_url}/session/#{session_id}/element/#{element_id}/value",
      body,
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, %{status_code: 200}} ->
        IO.puts("Typed text successfully")
        {:ok, session_id}
      
      {:error, reason} ->
        IO.puts("Failed to type: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def click_element(session_id, element_id) do
    body = Jason.encode!(%{})
    case HTTPoison.post(
      "#{@chromedriver_url}/session/#{session_id}/element/#{element_id}/click",
      body,
      [{"Content-Type", "application/json"}]
    ) do
      {:ok, %{status_code: 200}} ->
        IO.puts("Clicked successfully")
        {:ok, session_id}

      {:error, reason} ->
        IO.puts("Failed to click: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def wait(ms \\ 2000) do
    Process.sleep(ms)
    :ok
  end

  def login do
    email    = Application.get_env(:jibble_bot, :email)
    password = Application.get_env(:jibble_bot, :password)
    {:ok, session_id} = create_session()
    navigate(session_id, "https://web.jibble.io")
    wait(3000)
    {:ok, element_id} = find_element(session_id, "[data-testid='emailOrPhone']")
    type_text(session_id, element_id, email)
    {:ok, element_id} = find_element(session_id, "input[name='password']")
    type_text(session_id, element_id, password)
    {:ok, button_id} = find_element(session_id, "[data-testid='login-button']")
    click_element(session_id, button_id)
    wait(3000)
    {:ok, session_id}
  end

  def clock_in do
    start_chromedriver()
    {:ok, session_id} = login()
    wait(10000)
    {:ok, button_id} = find_element(session_id, "[data-testid='button-clock-in']")
    click_element(session_id, button_id)
    wait(3000)
    {:ok, button_id} = find_element(session_id, "[data-testid='right-sidebar-confirm-btn']")
    click_element(session_id, button_id)
    wait(3000)
    close_session(session_id)
    stop_chromedriver()
  end

  def clock_out do
    start_chromedriver()
    {:ok, session_id} = login()
    wait(10000)
    {:ok, button_id} = find_element(session_id, "[data-testid='button-clock-out']")
    click_element(session_id, button_id)
    wait(3000)
    {:ok, button_id} = find_element(session_id, "[data-testid='right-sidebar-confirm-btn']")
    click_element(session_id, button_id)
    wait(3000)
    close_session(session_id)
    stop_chromedriver()
  end

end
