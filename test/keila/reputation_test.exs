defmodule Keila.ReputationTest do
  use ExUnit.Case, async: true
  alias Keila.Reputation

  describe "breach/1 (limiar de reputação — regras 5/6)" do
    test "não pausa abaixo da amostra mínima" do
      assert Reputation.breach(%{sent: 100, spam_rate: 0.9, hard_bounce_rate: 0.9}) == nil
    end

    test "detecta spam acima de 0,3%" do
      assert Reputation.breach(%{sent: 1000, spam_rate: 0.004, hard_bounce_rate: 0.0}) == "spam"
    end

    test "detecta hard bounce acima de 5%" do
      assert Reputation.breach(%{sent: 1000, spam_rate: 0.0, hard_bounce_rate: 0.06}) == "bounce"
    end

    test "ok dentro dos limiares" do
      assert Reputation.breach(%{sent: 1000, spam_rate: 0.0005, hard_bounce_rate: 0.01}) == nil
    end
  end

  test "thresholds/0 expõe os limiares" do
    t = Reputation.thresholds()
    assert t.spam == 0.003
    assert t.hard_bounce == 0.05
    assert t.min_sample == 500
  end
end
