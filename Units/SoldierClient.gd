extends "res://Units/Soldier.gd"

# Клиентский солдат. Создаётся исключительно через FactoryClient.
# owner_id задаётся фабрикой до вызова _ready(), поэтому никаких
# переопределений _ready() не требуется.
# Логика таргетинга (_is_enemy / _get_enemies_in_range) унаследована
# из Soldier.gd и корректно работает при owner_id != 1.
