#include "../Overlay/PrototypeOverlay.h"

#include "../Component/CharacterComponent.h"
#include "../DataSet/AbilityDataSet.h"
#include "../DataSet/JobDataSet.h"

#include <Engine/Overlay/CustomOverlayColors.h>

#include <Libs/Ecs/EntityComponentSystem.h>
#include <Libs/Rendering/RenderSystem.h>
#include <Libs/Resource/ResourceSystem.h>
#include <Libs/Resource/DataSet/DataSet.h>
#include <Libs/Utility/ImGuiUtilities.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <string>
#include <vector>

namespace tactics {

namespace {
struct BattleUnitView {
	entt::entity entity{};
	const component::CharName* name{};
	const component::CharAvatar* avatar{};
	const component::CharLoadout* loadout{};
	component::CharStats* stats{};
	const component::ChargeTime* chargeTime{};
	component::TacticalPosition* position{};
	component::BattleTeam team{};
	bool ready{};
};

template<typename T> const T* findById(const std::vector<T>& items, const HashId& id) {
	for (auto& item : items) {
		if (item.id == id) {
			return &item;
		}
	}
	return nullptr;
}
}

PrototypeOverlay::PrototypeOverlay(RenderSystem& renderSystem,
								   EntityComponentSystem& ecs,
								   resource::ResourceSystem& resourceSystem)
	: _renderSystem(renderSystem)
	, _resourceSystem(resourceSystem)
	, _ecs(ecs) {}

OverlayConfig PrototypeOverlay::getConfig() {
	OverlayConfig config;
	config.position = {5, 30};
	config.size = {1120, 0};
	config.isMenuBarButton = true;
	return config;
}

void PrototypeOverlay::update() {
	static int selectedCharacterIndex = 0;
	static const char* selectedCommand = "Inspect";

	CenteredTextColored(CustomOverlayColors::Colors::TitleTextColor, "Prototype Battle");

	using namespace component;
	auto view = _ecs.sceneRegistry().view<CharName, CharAvatar, CharLoadout, CharStats, ChargeTime, TacticalPosition, TacticalTeam>();

	std::vector<BattleUnitView> characters;
	std::vector<int> playerIndexes;
	std::vector<int> enemyIndexes;
	for (auto [entity, charName, charAvatar, charLoadout, charStats, chargeTime, tacticalPosition, tacticalTeam] : view.each()) {
		auto index = static_cast<int>(characters.size());
		characters.push_back({entity,
							  &charName,
							  &charAvatar,
							  &charLoadout,
							  &charStats,
							  &chargeTime,
							  &tacticalPosition,
							  tacticalTeam.team,
							  _ecs.sceneRegistry().any_of<CharBattleReady>(entity)});
		if (tacticalTeam.team == BattleTeam::Player) {
			playerIndexes.push_back(index);
		} else if (charStats.hp > 0) {
			enemyIndexes.push_back(index);
		}
	}

	if (characters.empty() || playerIndexes.empty()) {
		ImGui::Text("No battle units loaded.");
		return;
	}

	if (selectedCharacterIndex >= static_cast<int>(playerIndexes.size())) {
		selectedCharacterIndex = 0;
	}

	auto& selectedUnit = characters[playerIndexes[selectedCharacterIndex]];
	auto selectedName = selectedUnit.name->name.c_str();
	auto selectedStats = selectedUnit.stats;
	auto selectedChargeTime = selectedUnit.chargeTime;
	auto selectedReady = selectedUnit.ready;
	auto selectedTile = selectedUnit.position->tile;
	auto jobs = _resourceSystem.getResource<resource::DataSet<JobDataSet>>("jobs"_id);
	auto abilities = _resourceSystem.getResource<resource::DataSet<AbilityDataSet>>("abilities"_id);
	auto selectedJob = findById(jobs->data, selectedUnit.loadout->jobId);

	const int boardWidth = 8;
	const int boardHeight = 6;
	const auto tileX = [boardWidth](int tile) { return tile % boardWidth; };
	const auto tileY = [boardWidth](int tile) { return tile / boardWidth; };
	const auto distance = [&](int a, int b) { return std::abs(tileX(a) - tileX(b)) + std::abs(tileY(a) - tileY(b)); };
	const auto occupiedByPlayer = [&](int tile) {
		for (auto index : playerIndexes) {
			if (characters[index].position->tile == tile) {
				return true;
			}
		}
		return false;
	};
	const auto enemyAt = [&](int tile) {
		for (auto index : enemyIndexes) {
			if (characters[index].position->tile == tile && characters[index].stats->hp > 0) {
				return index;
			}
		}
		return -1;
	};
	const auto occupied = [&](int tile) { return occupiedByPlayer(tile) || enemyAt(tile) >= 0; };

	ImGui::Text("Objective: Defeat all enemies");
	ImGui::SameLine();
	ImGui::TextColored(selectedReady ? ImVec4{0.2f, 1.0f, 0.35f, 1.0f} : ImVec4{1.0f, 0.8f, 0.25f, 1.0f},
					   selectedReady ? "Active unit ready" : "Charging turns");

	ImGui::Separator();
	ImGui::BeginGroup();
	CenteredTextColored(CustomOverlayColors::Colors::TitleTextColor, "First Fight - Grassy Field");
	const ImVec2 battlefieldSize{690.0f, 520.0f};
	const ImVec2 battlefieldStart = ImGui::GetCursorScreenPos();
	ImGui::InvisibleButton("##firstFightBattlefield", battlefieldSize);
	auto* drawList = ImGui::GetWindowDrawList();
	drawList->AddRectFilled(battlefieldStart,
							ImVec2{battlefieldStart.x + battlefieldSize.x, battlefieldStart.y + battlefieldSize.y},
							IM_COL32(26, 29, 28, 255),
							6.0f);

	const std::array<int, 48> tileTypes{
		0, 0, 0, 2, 2, 0, 0, 0,
		0, 0, 1, 1, 2, 0, 5, 0,
		0, 1, 1, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 1, 1, 0,
		4, 0, 0, 2, 0, 1, 0, 0,
		4, 4, 0, 0, 0, 0, 0, 3,
	};
	const std::array<int, 48> tileHeights{
		2, 2, 2, 2, 2, 2, 1, 1,
		2, 2, 2, 2, 2, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1,
		0, 0, 0, 1, 1, 1, 1, 1,
		0, 0, 0, 0, 1, 1, 1, 1,
	};
	const std::array<HashId, 8> terrainTextures{
		"terrainGrass"_id,
		"terrainDirt"_id,
		"terrainStone"_id,
		"terrainBridge"_id,
		"terrainWater"_id,
		"terrainCrystal"_id,
		"terrainCliff"_id,
		"terrainStairs"_id,
	};

	const ImVec2 gridOrigin{battlefieldStart.x + 342.0f, battlefieldStart.y + 88.0f};
	const ImVec2 tileSize{112.0f, 78.0f};
	const float halfTileWidth = tileSize.x * 0.5f;
	const float halfTileHeight = 30.0f;
	const float heightStep = 16.0f;
	const auto tileCenter = [&](int tile) {
		auto x = static_cast<float>(tileX(tile));
		auto y = static_cast<float>(tileY(tile));
		return ImVec2{gridOrigin.x + (x - y) * halfTileWidth,
					  gridOrigin.y + (x + y) * halfTileHeight - static_cast<float>(tileHeights[tile]) * heightStep};
	};
	const auto screenToTile = [&](ImVec2 point) {
		auto sx = point.x - gridOrigin.x;
		auto sy = point.y - gridOrigin.y;
		auto column = (sx / halfTileWidth + sy / halfTileHeight) * 0.5f;
		auto row = (sy / halfTileHeight - sx / halfTileWidth) * 0.5f;
		auto tileColumn = static_cast<int>(std::floor(column + 0.5f));
		auto tileRow = static_cast<int>(std::floor(row + 0.5f));
		if (tileColumn < 0 || tileColumn >= boardWidth || tileRow < 0 || tileRow >= boardHeight) {
			return -1;
		}
		return tileRow * boardWidth + tileColumn;
	};

	for (int tile = 0; tile < boardWidth * boardHeight; ++tile) {
		auto center = tileCenter(tile);
		auto texture = _resourceSystem.getResource<resource::Texture>(terrainTextures[tileTypes[tile]]);
		drawList->AddImage((void*)(intptr_t)texture->rendererId,
						   ImVec2{center.x - tileSize.x * 0.5f, center.y - tileSize.y * 0.55f},
						   ImVec2{center.x + tileSize.x * 0.5f, center.y + tileSize.y * 0.45f},
						   ImVec2(0, 1),
						   ImVec2(1, 0));

		auto isSelectedTile = tile == selectedTile;
		auto isWalkable = tileTypes[tile] != 4 && tileTypes[tile] != 5;
		auto isMoveTile = selectedCommand == std::string("Move") && distance(selectedTile, tile) <= selectedStats->move && !occupied(tile) && isWalkable;
		auto isAttackTile = selectedCommand == std::string("Attack") && distance(selectedTile, tile) <= 1 && enemyAt(tile) >= 0;
		auto color = IM_COL32(255, 255, 255, 28);
		if (isMoveTile) {
			color = IM_COL32(80, 180, 255, 86);
		}
		if (isAttackTile) {
			color = IM_COL32(255, 72, 48, 104);
		}
		if (isSelectedTile) {
			color = IM_COL32(255, 210, 66, 150);
		}
		ImVec2 diamond[4] = {
			{center.x, center.y - halfTileHeight},
			{center.x + halfTileWidth, center.y},
			{center.x, center.y + halfTileHeight},
			{center.x - halfTileWidth, center.y},
		};
		drawList->AddConvexPolyFilled(diamond, 4, color);
		drawList->AddPolyline(diamond, 4, IM_COL32(255, 255, 255, 42), ImDrawFlags_Closed, 1.0f);
	}

	if (ImGui::IsItemClicked(ImGuiMouseButton_Left)) {
		auto clickedTile = screenToTile(ImGui::GetIO().MousePos);
		if (clickedTile >= 0) {
			auto clickedEnemy = enemyAt(clickedTile);
			auto clickedPlayer = -1;
			for (int i = 0; i < static_cast<int>(playerIndexes.size()); ++i) {
				if (characters[playerIndexes[i]].position->tile == clickedTile) {
					clickedPlayer = i;
				}
			}

			if (clickedPlayer >= 0) {
				selectedCharacterIndex = clickedPlayer;
				selectedCommand = "Inspect";
			} else if (selectedCommand == std::string("Move") && distance(selectedTile, clickedTile) <= selectedStats->move && !occupied(clickedTile) && tileTypes[clickedTile] != 4 && tileTypes[clickedTile] != 5) {
				selectedUnit.position->tile = clickedTile;
				selectedCommand = "Inspect";
			} else if (selectedCommand == std::string("Attack") && clickedEnemy >= 0 && distance(selectedTile, clickedTile) <= 1) {
				characters[clickedEnemy].stats->hp = static_cast<uint16_t>(std::max(0, static_cast<int>(characters[clickedEnemy].stats->hp) - 25));
				selectedCommand = "Inspect";
			} else if (clickedEnemy >= 0) {
				selectedCommand = "Attack";
			}
		}
	}

	for (auto index : enemyIndexes) {
		auto& enemy = characters[index];
		if (enemy.stats->hp <= 0) {
			continue;
		}
		auto texture = _resourceSystem.getResource<resource::Texture>(enemy.avatar->textureId);
		auto center = tileCenter(enemy.position->tile);
		drawList->AddImage((void*)(intptr_t)texture->rendererId,
						   ImVec2{center.x - 28.0f, center.y - 66.0f},
						   ImVec2{center.x + 28.0f, center.y + 6.0f},
						   ImVec2(0, 1),
						   ImVec2(1, 0));
		drawList->AddText(ImVec2{center.x - 18.0f, center.y + 8.0f},
						  IM_COL32(255, 85, 70, 255),
						  ("HP " + std::to_string(enemy.stats->hp)).c_str());
	}
	for (int i = 0; i < static_cast<int>(playerIndexes.size()); ++i) {
		auto& player = characters[playerIndexes[i]];
		auto texture = _resourceSystem.getResource<resource::Texture>(player.avatar->textureId);
		auto center = tileCenter(player.position->tile);
		auto tint = i == selectedCharacterIndex ? IM_COL32(255, 255, 255, 255) : IM_COL32(210, 230, 255, 255);
		drawList->AddImage((void*)(intptr_t)texture->rendererId,
						   ImVec2{center.x - 28.0f, center.y - 66.0f},
						   ImVec2{center.x + 28.0f, center.y + 6.0f},
						   ImVec2(0, 1),
						   ImVec2(1, 0),
						   tint);
	}
	ImGui::EndGroup();

	ImGui::SameLine();
	ImGui::BeginGroup();
	CenteredTextColored(CustomOverlayColors::Colors::TitleTextColor, "Selected Unit");
	auto charAvatar = selectedUnit.avatar;
	auto selectedTexture = _resourceSystem.getResource<resource::Texture>(charAvatar->textureId);
	auto selectedRatio = static_cast<float>(selectedTexture->info.height) / static_cast<float>(selectedTexture->info.width);
	ImGui::Image((void*)(intptr_t)selectedTexture->rendererId, ImVec2(96, 96 * selectedRatio), ImVec2(0, 1), ImVec2(1, 0));
	ImGui::SameLine();
	ImGui::BeginGroup();
	ImGui::Text("%s", selectedName);
	ImGui::Text("%s", selectedJob ? selectedJob->name.c_str() : "Unknown Job");
	ImGui::Text("HP: %d/%d", selectedStats->hp, selectedStats->maxHp);
	ImGui::Text("MP: %d/%d", selectedStats->mp, selectedStats->maxMp);
	ImGui::Text("CT: %.1f / 100", selectedChargeTime->chargeTime);
	ImGui::ProgressBar(selectedChargeTime->chargeTime / 100.0f, ImVec2(180, 0), "");
	ImGui::EndGroup();

	ImGui::Spacing();
	CenteredTextColored(CustomOverlayColors::Colors::TitleTextColor, "Skills");
	for (auto abilityId : selectedUnit.loadout->abilityIds) {
		auto ability = findById(abilities->data, abilityId);
		if (ability == nullptr) {
			continue;
		}
		auto buttonLabel = ability->name + "##skill" + ability->id.str();
		if (ImGui::Button(buttonLabel.c_str(), ImVec2(172, 28))) {
			selectedCommand = "Ability";
		}
		ImGui::SameLine();
		ImGui::Text("MP %d  R %d", ability->mpCost, ability->range);
		if (ImGui::IsItemHovered() || ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) {
			ImGui::SetTooltip("%s\n%s\nIcon: %s\nVFX: %s\nSFX: %s",
							  ability->category.c_str(),
							  ability->description.c_str(),
							  ability->iconId.str(),
							  ability->vfxId.str(),
							  ability->sfxId.str());
		}
	}

	ImGui::Spacing();
	if (ImGui::Button("Move", ImVec2(86, 32))) {
		selectedCommand = "Move";
	}
	ImGui::SameLine();
	if (ImGui::Button("Attack", ImVec2(86, 32))) {
		selectedCommand = "Attack";
	}
	ImGui::SameLine();
	if (ImGui::Button("Ability", ImVec2(86, 32))) {
		selectedCommand = "Ability";
	}
	if (ImGui::Button("Items", ImVec2(86, 32))) {
		selectedCommand = "Items";
	}
	ImGui::SameLine();
	if (ImGui::Button("Wait", ImVec2(86, 32))) {
		selectedCommand = "Wait";
	}
	ImGui::SameLine();
	if (ImGui::Button("End Turn", ImVec2(86, 32))) {
		selectedCommand = "End Turn";
	}

	ImGui::Spacing();
	ImGui::Text("Command: %s", selectedCommand);
	ImGui::Text("Tile: %d", selectedTile);
	ImGui::Text("Move: %d  Jump: %d  Speed: %.1f", selectedStats->move, selectedStats->jump, selectedChargeTime->speed);

	ImGui::Spacing();
	CenteredTextColored(CustomOverlayColors::Colors::TitleTextColor, "Turn Order");
	for (int i = 0; i < static_cast<int>(playerIndexes.size()); ++i) {
		auto name = characters[playerIndexes[i]].name->name.c_str();
		if (ImGui::Selectable(name, selectedCharacterIndex == i, 0, ImVec2(260, 0))) {
			selectedCharacterIndex = i;
		}
	}
	ImGui::EndGroup();

	ImGui::Separator();
	CenteredTextColored(CustomOverlayColors::Colors::TitleTextColor, "Character Data");
	int columnCount = static_cast<int>(characters.size());
	if (columnCount > 0 &&
		ImGui::BeginTable("CharacterTable", columnCount, ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg)) {
		// Header row: Character names
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			ImGui::Text("%s", characters[col].name->name.c_str());
		}
		// Avatar row
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			auto tableAvatar = characters[col].avatar;
			auto texture = _resourceSystem.getResource<resource::Texture>(tableAvatar->textureId);
			auto width = static_cast<float>(texture->info.width);
			auto height = static_cast<float>(texture->info.height);
			auto ratio = height / width;
			ImGui::Image((void*)(intptr_t)texture->rendererId, ImVec2(64, 64 * ratio), ImVec2(0, 1), ImVec2(1, 0));
		}
		// Charge Time row
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			if (characters[col].ready) {
				ImGui::TextColored({0, 1, 0, 1}, "READY");
				ImGui::Button("DO ACTION");
			} else {
				ImGui::TextColored({1, 1, 1, 1}, "CHARGING");
				auto chargeTime = characters[col].chargeTime;
				ImGui::Text("CT: %.2f", chargeTime->chargeTime);
				ImGui::ProgressBar(chargeTime->chargeTime / 100.0f, ImVec2(-1, 0), "");
			}
		}
		// HP row
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			auto charStats = characters[col].stats;
			ImGui::Text("HP: %d/%d", charStats->hp, charStats->maxHp);
		}
		// MP row
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			auto charStats = characters[col].stats;
			ImGui::Text("MP: %d/%d", charStats->mp, charStats->maxMp);
		}
		// Level row
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			auto charStats = characters[col].stats;
			ImGui::Text("Level: %d", charStats->level);
		}
		// XP row
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			auto charStats = characters[col].stats;
			ImGui::Text("XP: %d", charStats->xp);
		}
		// Move row
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			auto charStats = characters[col].stats;
			ImGui::Text("Move: %d", charStats->move);
		}
		// Jump row
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			auto charStats = characters[col].stats;
			ImGui::Text("Jump: %d", charStats->jump);
		}
		// Speed row
		ImGui::TableNextRow();
		for (int col = 0; col < columnCount; ++col) {
			ImGui::TableSetColumnIndex(col);
			auto chargeTime = characters[col].chargeTime;
			ImGui::Text("Speed: %.2f", chargeTime->speed);
		}
		ImGui::EndTable();
	}

	ImGui::Spacing();
	CenteredTextColored(CustomOverlayColors::Colors::TitleTextColor, "Generated Prototype Assets");
	auto atlas = _resourceSystem.getResource<resource::Texture>("prototypeTacticsAtlas"_id);
	auto atlasWidth = static_cast<float>(atlas->info.width);
	auto atlasHeight = static_cast<float>(atlas->info.height);
	auto previewWidth = 280.0f;
	auto previewHeight = previewWidth * atlasHeight / atlasWidth;
	ImGui::Image((void*)(intptr_t)atlas->rendererId, ImVec2(previewWidth, previewHeight), ImVec2(0, 1), ImVec2(1, 0));
}

} // namespace tactics
