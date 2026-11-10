"""The Web acceptance gate must reject mixed, missing, or unreachable command menus."""
import copy
import unittest

import browser_courtyard_smoke as browser


class CommandMenuTests(unittest.TestCase):
    def menu(self, category='magic', school='', ids=('black', 'time')):
        key = 'magic_school' if category == 'magic' and not school else 'ability_id'
        return {
            'selected': 'zane', 'unit': {'id': 'zane'}, 'command': 'ability',
            'category': category, 'school': school, 'menu_visible': True,
            'entries': [{key: value, 'visible': True, 'disabled': False,
                         'rect': [20, 20 + i * 60, 300, 50]} for i, value in enumerate(ids)],
        }

    def test_school_gate_rejects_missing_extra_and_duplicate_schools(self):
        for ids in [('black',), ('black', 'time', 'white'), ('black', 'black', 'time')]:
            with self.subTest(ids=ids), self.assertRaises(AssertionError):
                browser.assert_command_menu(self.menu(ids=ids), 'magic', '', ['black', 'time'])
        browser.assert_command_menu(self.menu(), 'magic', '', ['black', 'time'])

    def test_leaf_gate_rejects_cross_school_or_skill_leakage(self):
        valid = self.menu(school='black', ids=('fire', 'thunderstrike', 'void_pulse'))
        browser.assert_command_menu(valid, 'magic', 'black', ['fire', 'thunderstrike', 'void_pulse'])
        for field, value in [('category', 'skills'), ('school', 'time'), ('command', 'ability_target'),
                             ('menu_visible', False), ('selected', 'kael')]:
            with self.subTest(field=field), self.assertRaises(AssertionError):
                browser.assert_command_menu({**valid, field: value}, 'magic', 'black',
                                            ['fire', 'thunderstrike', 'void_pulse'])
        mixed = copy.deepcopy(valid)
        mixed['entries'][0]['magic_school'] = 'black'
        with self.assertRaises(AssertionError):
            browser.assert_command_menu(mixed, 'magic', 'black', ['fire', 'thunderstrike', 'void_pulse'])

    def test_skill_gate_requires_exact_owned_skills_without_school_row(self):
        skills = ['mighty_strike', 'defend', 'delay_strike', 'heavy_slash']
        valid = self.menu(category='skills', ids=skills)
        browser.assert_command_menu(valid, 'skills', '', skills)
        valid['entries'].append({'magic_school': 'black', 'visible': True, 'disabled': False})
        with self.assertRaises(AssertionError):
            browser.assert_command_menu(valid, 'skills', '', skills)

    def test_entry_lookup_rejects_hidden_disabled_and_ambiguous_controls(self):
        state = self.menu()
        self.assertEqual(browser.menu_entry(state, 'magic_school', 'time')['rect'], [20, 80, 300, 50])
        for change in [{'visible': False}, {'disabled': True}]:
            invalid = copy.deepcopy(state)
            invalid['entries'][1].update(change)
            with self.assertRaises(AssertionError):
                browser.menu_entry(invalid, 'magic_school', 'time')
        state['entries'].append(dict(state['entries'][1]))
        with self.assertRaises(AssertionError):
            browser.menu_entry(state, 'magic_school', 'time')

    def test_commands_gate_rejects_enabled_empty_category_and_hidden_command(self):
        state = {'command': '', 'menu_visible': False, 'review': False,
                 'buttons': {'magic': {'visible': True, 'disabled': False},
                             'skills': {'visible': True, 'disabled': True}}}
        browser.assert_commands(state, magic=True, skills=False)
        for name, field, value in [('skills', 'disabled', False), ('magic', 'visible', False)]:
            invalid = copy.deepcopy(state)
            invalid['buttons'][name][field] = value
            with self.assertRaises(AssertionError):
                browser.assert_commands(invalid, magic=True, skills=False)


if __name__ == '__main__':
    unittest.main()
