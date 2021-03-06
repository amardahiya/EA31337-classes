//+------------------------------------------------------------------+
//|                                                EA31337 framework |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 *  This file is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * @file
 * Test functionality of Dict class.
 */

// Includes.
#include "../Dict.mqh"
#include "../DictObject.mqh"
#include "../DictStruct.mqh"
#include "../Json.mqh"
#include "../Object.mqh"
#include "../Test.mqh"

class DictTestClass {
 public:
  int _value;

  DictTestClass(int value = 0) : _value(value) {}

  DictTestClass(const DictTestClass& r) : _value(r._value) {}

  bool operator==(const DictTestClass& r) { return _value == r._value; }

  JsonNodeType Serialize(JsonSerializer& s) {
    s.Pass(this, "value", _value);

    return JsonNodeObject;
  }
};

/**
 * Implements OnInit().
 */
int OnInit() {
  // Example 1.
  Dict<string, int> dict1;

  dict1.Set("a", 1);
  dict1.Set("bb", 2);
  dict1.Unset("bb");
  dict1.Set("b", 2);
  dict1.Set("c", 33);
  dict1.Set("c", 3);
  assertTrueOrFail(dict1.GetByKey("a") == 1, "Invalid Dict value, expected 1!");
  assertTrueOrFail(dict1.GetByKey("b") == 2, "Invalid Dict value, expected 2!");
  assertTrueOrFail(dict1.GetByKey("c") == 3, "Invalid Dict value, expected 3!");
  assertTrueOrFail(dict1.Contains("b", 2), "Wrong Contains() method logic. Dict contain that key -> value pair!");
  Print("dict1: ", JSON::Stringify(dict1));

  // Example 2.
  Dict<int, string> dict2;
  dict2.Set(1, "a");
  dict2.Set(2, "bb");
  dict2.Unset(2);
  dict2.Set(2, "b");
  dict2.Set(3, "cc");
  dict2.Set(3, "c");
  assertTrueOrFail(dict2.GetByKey(1) == "a", "Invalid Dict value, expected 'a'!");
  assertTrueOrFail(dict2.GetByKey(2) == "b", "Invalid Dict value, expected 'b'!");
  assertTrueOrFail(dict2.GetByKey(3) == "c", "Invalid Dict value, expected 'c'!");
  Print("dict2: ", JSON::Stringify(dict2));

  // Example 3. Dictionary of pointers to other dictionaries.
  Dict<int, Dict<int, string>*> dict3;

  dict3.Set(1, &dict2);
  assertTrueOrFail(dict3.Contains(1, &dict2), "Wrong Contains() method logic. Dict contain that key -> value pair!");
  Dict<int, string>* dict2_ref = dict3.GetByKey(1);
  assertTrueOrFail(dict2_ref != NULL, "Dict should return non-NULL pointer to the dict2 object!");
  assertTrueOrFail(dict2_ref.GetByKey(1) == "a", "Incorrect value read from dict2 object. Expected 'a' for key 1!");
  dict2.Set(1, "d");
  assertTrueOrFail(dict2_ref.GetByKey(1) == "d",
                   "Reference to dict2 doesn't point to the dict2 object, but rather to a copy of dict2. It is wrong!");
  dict2_ref.Unset(1);
  assertTrueOrFail(dict2_ref.KeyExists(1) == false, "Dict shouldn't contain key 1 as it was unset!");
  Print("dict3: ", JSON::Stringify(dict3));

  // Example 4. Dictionary of other dictionaries.
  DictObject<int, Dict<int, string>> dict4;
  dict4.Set(1, dict2);
  Dict<int, string>* dict2_ref2 = dict4.GetByKey(1);
  assertTrueOrFail(dict2_ref2 != NULL, "Dict should return non-NULL pointer to the dict2 object!");
  assertTrueOrFail(dict2_ref2.GetByKey(2) == "b", "Incorrect value read from dict2 object. Expected 'b' for key 2!");
  dict2.Set(2, "e");
  assertTrueOrFail(
      dict2_ref2.GetByKey(2) == "b",
      "Reference to dict2 points to the same dict2 object as the one passed. It should be copied by value!");
  dict2_ref.Unset(1);
  assertTrueOrFail(dict2_ref.KeyExists(1) == false, "Dict shouldn't contain key 1 as it was unset!");
  dict4.Unset(1);
  assertTrueOrFail(dict4.KeyExists(1) == false, "Dict shouldn't contain key 1 as it was unset!");
  Print("dict4: ", JSON::Stringify(dict4));

  // Example 5. Dictionary ToJSON() method.
  DictObject<int, Dict<int, string>> dict5;
  Dict<int, string> dict5_1;
  dict5_1.Push("c");
  dict5_1.Push("b");
  dict5_1.Push("a");
  Dict<int, string> dict5_2;
  dict5_2.Push("a");
  dict5_2.Push("b");
  dict5_2.Push("c");
  dict5.Set(1, dict5_1);
  dict5.Set(2, dict5_2);
  assertTrueOrFail(JSON::Stringify(dict5, true) == "{\"1\":[\"c\",\"b\",\"a\"],\"2\":[\"a\",\"b\",\"c\"]}",
                   "Improper white-space-stripped JSON output!");
  assertTrueOrFail(JSON::Stringify(dict5, false, 2) ==
                       "{\n  \"1\": [\n    \"c\",\n    \"b\",\n    \"a\"\n  ],\n  \"2\": [\n    \"a\",\n    \"b\",\n   "
                       " \"c\"\n  ]\n}",
                   "Improper white-spaced JSON output!");
  Print("dict5: ", JSON::Stringify(dict5));

  // Example 6. Enum values as key.
  Dict<int, string> dict6;
  dict6.Set(PERIOD_M1, "1 min");
  dict6.Set(PERIOD_M5, "5 min");
  assertTrueOrFail(dict6.GetByKey(PERIOD_M1) == "1 min",
                   "Wrongly set Dict key. Expected '1 min' for enum key PERIOD_M1!");
  assertTrueOrFail(dict6.GetByKey(PERIOD_M5) == "5 min",
                   "Wrongly set Dict key. Expected '5 min' for enum key PERIOD_M5!");
  Print("dict6: ", JSON::Stringify(dict6));

  // Example 7. Enum values as value.
  Dict<string, int> dict7;
  dict7.Set("1 min", PERIOD_M1);
  dict7.Set("5 min", PERIOD_M5);
  assertTrueOrFail(dict7.GetByKey("1 min") == PERIOD_M1,
                   "Wrongly set Dict key. Expected PERIOD_M1's value for '1 min' key!");
  assertTrueOrFail(dict7.GetByKey("5 min") == PERIOD_M5,
                   "Wrongly set Dict key. Expected PERIOD_M5's value for '5 min' key!");
  Print("dict7: ", JSON::Stringify(dict7));

  // Testing iteration over simple types.
  Dict<int, string> dict8;
  dict8.Set(1, "One");
  dict8.Set(2, "Two");
  dict8.Set(3, "Three");

  Dict<int, string> dict8_found;

  for (DictIterator<int, string> iter = dict8.Begin(); iter.IsValid(); ++iter) {
    dict8_found.Set(iter.Key(), iter.Value());
  }

  assertTrueOrFail(dict8_found.Size() == 3, "Wrong interator logic. Should iterate over exactly 3 keys (found " +
                                                IntegerToString(dict8_found.Size()) + ")!");
  assertTrueOrFail(dict8_found.GetByKey(1) == "One", "Wrong interator logic. Should interate over key 1!");
  assertTrueOrFail(dict8_found.GetByKey(2) == "Two", "Wrong interator logic. Should interate over key 1!");
  assertTrueOrFail(dict8_found.GetByKey(3) == "Three", "Wrong interator logic. Should interate over key 1!");
  Print("dict8: ", JSON::Stringify(dict8));

  // Testing iteration over class types.
  DictObject<int, Dict<int, string>> dict9;
  Dict<int, string> dict9_a;
  Dict<int, string> dict9_b;
  Dict<int, string> dict9_c;
  dict9_a.Set(1, "One");
  dict9_a.Set(2, "Two");
  dict9_b.Set(3, "Three");
  dict9_b.Set(4, "Four");
  dict9_c.Set(5, "Five");
  dict9_c.Set(6, "Six");
  dict9.Push(dict9_a);
  dict9.Push(dict9_b);
  dict9.Push(dict9_c);
  Print("dict9: ", JSON::Stringify(dict9));

  assertTrueOrFail(dict9[0] != NULL, "Dict has item at index 1 but returned NULL!");
  assertTrueOrFail(dict9[4] == NULL, "Dict has no item at index 4 but returned non-NULL value!");
  assertTrueOrFail(dict9[0][2] == "Two", "Wrong value returned for first Dict for key 2. It should be \"Two\"");
  assertTrueOrFail(dict9[0][5] == NULL,
                   "Wrong value returned for first Dict for key 5. As it has no such key, it should return NULL!");

  for (DictObjectIterator<int, Dict<int, string>> iter = dict9.Begin(); iter.IsValid(); ++iter) {
    assertTrueOrFail(iter.Key() == 0 ? (iter.Value()[1] == "One") : true,
                     "Wrong interator logic. First Dict should contain [1 => \"One\"]!");
    assertTrueOrFail(iter.Key() == 1 ? (iter.Value()[3] == "Three") : true,
                     "Wrong interator logic. Second Dict should contain [3 => \"Three\"]!");
    assertTrueOrFail(iter.Key() == 2 ? (iter.Value()[5] == "Five") : true,
                     "Wrong interator logic. Second Dict should contain [5 => \"Five\"]!");
  }

  int i;

  // Testing insertion by Set().
  Dict<int, int> dict10;
  for (i = 0; i < 100; ++i) {
    assertTrueOrFail(dict10.Set(i, i), "Cannot insert value into Dict (by Set()). Probably a bug in Resize() method!");
  }
  Print("dict10: ", JSON::Stringify(dict10));
  
  assertTrueOrFail(dict10.Size() == 100, "Wrong values count!");
  
  for (i = 0; i < 100; ++i) {
    assertTrueOrFail(dict10.GetByKey(i) == i, "Wrong value found!");
  }

  // Testing insertion by Push().
  Dict<int, int> dict11;
  for (i = 0; i < 100; ++i) {
    assertTrueOrFail(dict11.Push(i), "Cannot insert value into Dict (by Set()). Probably a bug in Resize() method!");
  }
  Print("dict11: ", JSON::Stringify(dict11));
  
  assertTrueOrFail(dict11.Size() == 100, "Wrong values count!");

  for (i = 0; i < 100; ++i) {
    assertTrueOrFail(dict11[i] == i, "Wrong value found!");
  }

  DictTestClass testClass1_5(5);
  DictTestClass testClass2_5(5);
  DictTestClass testClass3_2(2);
  DictObject<int, DictTestClass> dict12;
  dict12.Set(1, testClass1_5);
  assertTrueOrFail(dict12.Contains(1, testClass1_5),
                   "Wrong Contains() method logic. Dict contain that key -> value pair!");
  assertTrueOrFail(dict12.Contains(1, testClass2_5),
                   "Wrong Contains() method logic. Dict contain that key -> value pair!");
  assertTrueOrFail(!dict12.Contains(1, testClass3_2),
                   "Wrong Contains() method logic. Dict does not contain that key -> value pair!");
  Print("dict12: ", JSON::Stringify(dict12));

  return (INIT_SUCCEEDED);
}
