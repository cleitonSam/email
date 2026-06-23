defmodule Keila.Contacts.EmailHygieneTest do
  use ExUnit.Case, async: true
  alias Keila.Contacts.EmailHygiene

  test "valid_syntax?/1" do
    assert EmailHygiene.valid_syntax?("a@b.com")
    refute EmailHygiene.valid_syntax?("a@b")
    refute EmailHygiene.valid_syntax?("sem-arroba")
    refute EmailHygiene.valid_syntax?(nil)
  end

  test "disposable?/1" do
    assert EmailHygiene.disposable?("x@mailinator.com")
    assert EmailHygiene.disposable?("X@YopMail.com")
    refute EmailHygiene.disposable?("x@gmail.com")
    refute EmailHygiene.disposable?(nil)
  end

  test "classify/1" do
    assert EmailHygiene.classify("x@gmail.com") == :ok
    assert EmailHygiene.classify("ruim@") == :invalid_syntax
    assert EmailHygiene.classify("x@tempmail.com") == :disposable
  end

  test "domain/1 normaliza" do
    assert EmailHygiene.domain(" A@B.com ") == "b.com"
    assert EmailHygiene.domain("bad") == nil
  end
end
