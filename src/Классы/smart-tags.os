#Использовать logos

Перем ВерсияПлагина;
Перем Лог;
Перем Обработчик;
Перем КомандыПлагина;
Перем ПропускатьСуществующиеТеги;
Перем ПоследняяВерсияКонфигурации;
Перем ТекущаяВерсияКонфигурации;

Функция ОписаниеПлагина() Экспорт

	Возврат Новый Структура("Версия, Лог, ИмяПакета", ВерсияПлагина, Лог, ИмяПлагина())

КонецФункции // Информация() Экспорт

Процедура ПриАктивизацииПлагина(СтандартныйОбработчик) Экспорт

	Обработчик = СтандартныйОбработчик;
	ПоследняяВерсияКонфигурации = "";
	ТекущаяВерсияКонфигурации = "";

КонецПроцедуры

Процедура ПриРегистрацииКомандыПриложения(ИмяКоманды, КлассРеализации, Парсер) Экспорт

	Лог.Отладка("Ищю команду <%1> в списке поддерживаемых", ИмяКоманды);
	Если КомандыПлагина.Найти(ИмяКоманды) = Неопределено Тогда
		Возврат;
	КонецЕсли;

	Лог.Отладка("Устанавливаю дополнительные параметры для команды %1", ИмяКоманды);

	ПропускатьСуществующиеТеги = КлассРеализации.Опция("S skip-exists-tags", Ложь, "[*skip-exists-tags] флаг пропуска ошибок создания существующих тегов").Флаговый();

КонецПроцедуры

Процедура ПриПолученииПараметров(ПараметрыКоманды, ДополнительныеПараметры) Экспорт

	ПропускатьСуществующиеТеги = ПараметрыКоманды["--skip-exists-tags"];

	Если ПропускатьСуществующиеТеги = Неопределено Тогда
		ПропускатьСуществующиеТеги = Ложь;
	КонецЕсли;

КонецПроцедуры

Процедура ПередНачаломВыполнения(ПутьКХранилищу, КаталогРабочейКопии, URLРепозитория, ИмяВетки) Экспорт

	ПоследняяВерсияКонфигурации = ПрочитатьВерсиюИзИсходников(КаталогРабочейКопии);

КонецПроцедуры

Процедура ПередОбработкойВерсииХранилища(СтрокаВерсии, СледующаяВерсия) Экспорт

	Если ЗначениеЗаполнено(СтрокаВерсии.Тэг) Тогда
		ТекущаяВерсияКонфигурации = СтрокаВерсии.Тэг;
	КонецЕсли;

КонецПроцедуры

Процедура ПослеКоммита(ГитРепозиторий, КаталогРабочейКопии) Экспорт

	Если ПустаяСтрока(ТекущаяВерсияКонфигурации) Тогда
		ТекущаяВерсияКонфигурации = ПрочитатьВерсиюИзИсходников(КаталогРабочейКопии);
	КонецЕсли;

	Если ПоследняяВерсияКонфигурации <> ТекущаяВерсияКонфигурации
		И ЗначениеЗаполнено(ТекущаяВерсияКонфигурации) Тогда
		Лог.Информация("Определена новая версия конфигурации: %1. Будет установлен новый тег", ТекущаяВерсияКонфигурации);

		ПараметрыКоманды = Новый Массив;
		ПараметрыКоманды.Добавить("tag");
		ПараметрыКоманды.Добавить(Строка(ТекущаяВерсияКонфигурации));

		Попытка
			ГитРепозиторий.ВыполнитьКоманду(ПараметрыКоманды);
		Исключение
			ТекстОшибки = ОписаниеОшибки();
			Если ПропускатьСуществующиеТеги
				И ЭтоОшибкаТегУжеСуществует(ТекстОшибки, ТекущаяВерсияКонфигурации) Тогда
				Лог.Ошибка(ТекстОшибки);
			Иначе
				ВызватьИсключение ТекстОшибки;
			КонецЕсли;
		КонецПопытки;

		ПоследняяВерсияКонфигурации = ТекущаяВерсияКонфигурации;

	КонецЕсли;

КонецПроцедуры

Функция ПрочитатьВерсиюИзИсходников(КаталогИсходныхФайлов)

	ФайлКонфигурации = Новый Файл(ОбъединитьПути(КаталогИсходныхФайлов, "Configuration.xml"));
	Если Не ФайлКонфигурации.Существует() Тогда
		Возврат ПоследняяВерсияКонфигурации;
	КонецЕсли;

	ПараметрыКонфигурации = ПолучитьПараметрыКонфигурацииИзИсходников(КаталогИсходныхФайлов);

	Возврат ПараметрыКонфигурации.Version;

КонецФункции // ПрочитатьВерсиюИзИсходников()

Функция ЭтоОшибкаТегУжеСуществует(ТекстОшибки, ТекущаяВерсияКонфигурации)

	Возврат СтрНайти(
		ТекстОшибки,
		СтрШаблон("fatal: tag '%1' already exists", ТекущаяВерсияКонфигурации)) > 0;

КонецФункции

// Функция читает параметры конфигурации из каталога исходников
//
Функция ПолучитьПараметрыКонфигурацииИзИсходников(КаталогИсходныхФайлов)

	ФайлКонфигурации = Новый Файл(ОбъединитьПути(КаталогИсходныхФайлов, "Configuration.xml"));
	Если Не ФайлКонфигурации.Существует() Тогда
 		ВызватьИсключение СтрШаблон("Файл <%1> не найдет у указанном каталоге.", ФайлКонфигурации.ПолноеИмя);
	КонецЕсли;

	ПараметрыКонфигурации = Новый Структура;

	Чтение = Новый ЧтениеXML;
	Чтение.ОткрытьФайл(ФайлКонфигурации.ПолноеИмя);

	Пока Чтение.Прочитать() Цикл
		Если Чтение.ТипУзла = ТипУзлаXML.НачалоЭлемента И Чтение.Имя = "Properties" Тогда
			Прервать;
		КонецЕсли;
	КонецЦикла;

	//Чтение на следующий элемент
	Чтение.Прочитать();

	МассивДоступныхСвойств = Новый Массив;
	МассивДоступныхСвойств.Добавить("Vendor");
	МассивДоступныхСвойств.Добавить("Version");
	МассивДоступныхСвойств.Добавить("UpdateCatalogAddress");
	МассивДоступныхСвойств.Добавить("Comment");
	МассивДоступныхСвойств.Добавить("Name");

	Пока Не (Чтение.ТипУзла = ТипУзлаXML.КонецЭлемента и Чтение.ЛокальноеИмя = "Properties") Цикл

		КлючИЗначение = ПрочитатьОпцию(Чтение);

		Если МассивДоступныхСвойств.Найти(КлючИЗначение.Ключ) = Неопределено  Тогда
			Продолжить;
		КонецЕсли;

		ПараметрыКонфигурации.Вставить(КлючИЗначение.Ключ, КлючИЗначение.Значение);

	КонецЦикла;
	Чтение.Закрыть();

	Возврат ПараметрыКонфигурации;

КонецФункции

// Функция читает опцию из ЧтениеXML
//
Функция ПрочитатьОпцию(Знач Чтение)

	Перем Ключ;
	Перем Значение;

	Ключ = Чтение.ЛокальноеИмя;

	Чтение.Прочитать();
	Если Чтение.ТипУзла = ТипУзлаXML.Текст Тогда
		Значение = Чтение.Значение;
		Чтение.Прочитать();
	ИначеЕсли Чтение.ТипУзла = ТипУзлаXML.КонецЭлемента Тогда
		Значение = "";
	Иначе

	КонецЕсли;

	Лог.Отладка("Читаю опцию: %1
	| Значение: %2",Ключ,Значение);

	Чтение.Прочитать();

	Возврат Новый Структура("Ключ,Значение", Ключ, Значение);

КонецФункции

Функция ИмяПлагина()
	возврат "smart-tags";
КонецФункции // ИмяПлагина()

Процедура Инициализация()

	ВерсияПлагина = "1.0.0";
	Лог = Логирование.ПолучитьЛог("oscript.app.gitsync_plugins_"+ СтрЗаменить(ИмяПлагина(),"-", "_"));
	КомандыПлагина = Новый Массив;
	КомандыПлагина.Добавить("sync");
	КомандыПлагина.Добавить("export");
	ПоследняяВерсияКонфигурации = "";
	ТекущаяВерсияКонфигурации = "";

КонецПроцедуры

Инициализация();
