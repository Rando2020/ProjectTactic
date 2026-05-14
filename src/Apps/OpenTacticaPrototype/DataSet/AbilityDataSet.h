#pragma once

#include <Libs/Resource/DataSet/DataSetReflection.h>

namespace tactics {

struct AbilityDataSet {
	HashId id;
	std::string name;
	std::string category;
	HashId iconId;
	HashId vfxId;
	HashId sfxId;
	uint8_t range{};
	uint8_t area{};
	uint8_t mpCost{};
	uint16_t power{};
	std::string description;

	DATASET(AbilityDataSet, id, name, category, iconId, vfxId, sfxId, range, area, mpCost, power, description);
};

} // namespace tactics
