#pragma once

#include <Libs/Resource/DataSet/DataSetReflection.h>

namespace tactics {

struct JobDataSet {
	HashId id;
	std::string name;
	HashId spriteId;
	HashId portraitId;
	uint16_t baseHp{};
	uint16_t baseMp{};
	uint8_t move{};
	uint8_t jump{};
	float speed{};
	std::vector<HashId> abilityIds;

	DATASET(JobDataSet, id, name, spriteId, portraitId, baseHp, baseMp, move, jump, speed, abilityIds);
};

} // namespace tactics
