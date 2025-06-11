extends Control

@onready var name_edit = $Panel/VBoxContainer/NameEdit
@onready var age_edit = $Panel/VBoxContainer/AgeEdit
@onready var country_edit = $Panel/VBoxContainer/CountryEdit
@onready var guest_button = $Panel/VBoxContainer/ButtonContainer/GuestButton
@onready var create_user_button = $Panel/VBoxContainer/ButtonContainer/CreateUserButton
@onready var password_edit = $Panel/VBoxContainer/PasswordEdit
@onready var login_button = $Panel/VBoxContainer/LoginButton

func _ready():
    guest_button.pressed.connect(_on_guest_pressed)
    create_user_button.pressed.connect(_on_create_user_pressed)
    login_button.pressed.connect(_on_login_pressed)

func _on_guest_pressed():
    print("Guest login")
    # TODO: Integrate Firebase anonymous login
    # get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_create_user_pressed():
    var name = name_edit.text.strip_edges()
    var age = age_edit.text.strip_edges()
    var country = country_edit.text.strip_edges()
    var password = password_edit.text.strip_edges()
    if name == "" or age == "" or country == "" or password == "":
        print("Please fill in all fields.")
        return
    print("Register user:", name, age, country, password)
    # TODO: Integrate Firebase registration
    # get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_login_pressed():
    var name = name_edit.text.strip_edges()
    var password = password_edit.text.strip_edges()
    if name == "" or password == "":
        print("Please enter name and password to login.")
        return
    print("Login user:", name, password)
    # TODO: Integrate Firebase login
    # get_tree().change_scene_to_file("res://scenes/menu.tscn")