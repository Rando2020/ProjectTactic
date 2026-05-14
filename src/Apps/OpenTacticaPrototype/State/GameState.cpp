#include "GameState.h"

#include "../Component/CharacterComponent.h"
#include "../DataSet/CharacterDataSet.h"
#include "../Overlay/PrototypeOverlay.h"

#include <Engine/Scene/SceneSystem.h>

#include <Libs/Ecs/Component/TransformComponent.h>
#include <Libs/Ecs/EntityComponentSystem.h>
#include <Libs/Input/InputSystem.h>
#include <Libs/Overlay/OverlaySystem.h>
#include <Libs/Resource/DataSet/DataSetSystem.h>
#include <Libs/Resource/ResourceSystem.h>
#include <Libs/Utility/Time/EngineTime.h>

#include <array>
#include <vector>

namespace tactics {

Entity createCharacterFromData(const CharacterDataSet& charData, SceneSystem& sceneSystem, const glm::vec3& position) {
	auto entity = sceneSystem.createEntity(HashId(charData.name), "character"_id);
	entity.getComponent<component::CharName>().name = charData.name;
	entity.getComponent<component::CharAvatar>().textureId = charData.avatarId;
	auto& loadout = entity.addComponent<component::CharLoadout>();
	loadout.jobId = charData.jobId;
	loadout.abilityIds = charData.abilityIds;
	auto& charStats = entity.getComponent<component::CharStats>();
	charStats.hp = charData.hp;
	charStats.maxHp = charData.hp;
	charStats.mp = charData.mp;
	charStats.maxMp = charData.mp;
	charStats.level = charData.level;
	charStats.xp = charData.xp;
	charStats.move = charData.move;
	charStats.jump = charData.jump;
	auto& chargeTime = entity.getComponent<component::ChargeTime>();
	chargeTime.chargeTime = 0.0f;
	chargeTime.speed = charData.speed;

	entity.getComponent<component::Transform>().setPosition(position);
	return entity;
}

Entity createBattleUnit(SceneSystem& sceneSystem,
						const HashId& name,
						const HashId& avatarId,
						int hp,
						int mp,
						int move,
						int jump,
						float speed,
						component::BattleTeam team,
						HashId jobId,
						std::vector<HashId> abilityIds,
						int tile,
						const glm::vec3& scenePosition) {
	auto entity = sceneSystem.createEntity(name, "character"_id);
	entity.getComponent<component::CharName>().name = name.str();
	entity.getComponent<component::CharAvatar>().textureId = avatarId;
	auto& loadout = entity.addComponent<component::CharLoadout>();
	loadout.jobId = jobId;
	loadout.abilityIds = abilityIds;
	auto& charStats = entity.getComponent<component::CharStats>();
	charStats.hp = static_cast<uint16_t>(hp);
	charStats.maxHp = static_cast<uint16_t>(hp);
	charStats.mp = static_cast<uint16_t>(mp);
	charStats.maxMp = static_cast<uint16_t>(mp);
	charStats.level = 1;
	charStats.xp = 0;
	charStats.move = static_cast<uint8_t>(move);
	charStats.jump = static_cast<uint8_t>(jump);
	auto& chargeTime = entity.getComponent<component::ChargeTime>();
	chargeTime.chargeTime = 0.0f;
	chargeTime.speed = speed;
	entity.addComponent<component::TacticalPosition>(tile, 0);
	entity.addComponent<component::TacticalTeam>(team);
	entity.getComponent<component::Transform>().setPosition(scenePosition);
	return entity;
}

FsmAction GameState::enter() {
	auto& sceneSystem = getService<SceneSystem>();
	auto& dataSetSystem = getService<resource::DataSetSystem>();
	auto characterDataSet = dataSetSystem.getDataSet<CharacterDataSet>("main_characters"_id);
	std::vector<glm::vec3> positions;
	auto x = 0.0f;
	std::transform(characterDataSet->data.begin(),
				   characterDataSet->data.end(),
				   std::back_inserter(positions),
				   [&x](const CharacterDataSet&) {
					   x += 1;
					   return glm::vec3{x, 0, 0};
				   });

	auto i = 0;
	const std::array<int, 4> playerTiles{34, 35, 42, 43};
	for (auto& charData : characterDataSet->data) {
		auto entity = createCharacterFromData(charData, sceneSystem, positions[i]);
		entity.addComponent<component::TacticalPosition>(playerTiles[i % playerTiles.size()], 0);
		entity.addComponent<component::TacticalTeam>(component::BattleTeam::Player);
		++i;
	}

	createBattleUnit(sceneSystem,
					 "Brigand Lancer"_id,
					 "enemyLancer"_id,
					 70,
					 10,
					 3,
					 2,
					 18.0f,
					 component::BattleTeam::Enemy,
					 "bramble_lancer"_id,
					 {"piercing_thrust"_id, "brace"_id},
					 10,
					 {-2.0f, 0.0f, 0.0f});
	createBattleUnit(sceneSystem,
					 "Brush Rogue"_id,
					 "enemyRogue"_id,
					 65,
					 20,
					 4,
					 2,
					 24.0f,
					 component::BattleTeam::Enemy,
					 "brush_rogue"_id,
					 {"knife_flurry"_id, "smoke_step"_id},
					 22,
					 {-1.0f, 0.0f, 0.0f});
	createBattleUnit(sceneSystem,
					 "Shade Knife"_id,
					 "enemyShadow"_id,
					 55,
					 30,
					 5,
					 3,
					 28.0f,
					 component::BattleTeam::Enemy,
					 "shade_knife"_id,
					 {"shadow_cut"_id, "dread_mark"_id},
					 30,
					 {0.0f, 0.0f, 0.0f});

	sceneSystem.createEntity("MainCamera"_id, "simpleCamera"_id);

	auto& overlaySystem = getService<OverlaySystem>();
	auto& resourceSystem = getService<resource::ResourceSystem>();
	overlaySystem.addOverlay<PrototypeOverlay>("PrototypeOverlay",
											   false,
											   getService<RenderSystem>(),
											   getService<EntityComponentSystem>(),
											   resourceSystem);

	return FsmAction::none();
}

void GameState::exit() {
	auto& sceneSystem = getService<SceneSystem>();
	sceneSystem.clearScene();

	auto& overlaySystem = getService<OverlaySystem>();
	overlaySystem.removeOverlay("PrototypeOverlay");
}

FsmAction GameState::update() {
	auto& inputSystem = getService<InputSystem>();
	if (inputSystem.checkAction("anyKeyPressed")) {
		return FsmAction::transition("exit"_id);
	}

	auto& registry = getService<SceneSystem>().getRegistry();

	float deltaTime = EngineTime::fixedDeltaTime<float>();
	component::BattleSystem::advanceTick(registry, deltaTime);

	return FsmAction::none();
}

} // namespace tactics
