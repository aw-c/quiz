--[[

    Test Technical Task for chelog, OctoTeam. 0:31 - 04.10.2021

]]

local quiz = quiz or {}; -- если мы хотим не терять данные при хотлоуде, луарефреше, например в одном из популярных фреймворков: Clockwork, CatWork, Nutscript, Helix и т.п
quiz.TimeToAnswer = 30;
quiz.QuestionEveryHowSeconds = 2;
quiz.Questions = quiz.Questions or {};
quiz.StartedQuestion = nil;
quiz.NextQuestion = CurTime() + quiz.QuestionEveryHowSeconds;

function quiz:AddQuestion(shortname,funcortable,willsave) --сюды мы обязаны передать короткое название викторины по которому админы смогу запускать его а также функцию генерации условия и правильного ответа или таблицу с вопросом и ответом. Будет ли сохранён вопрос?
    if self.Questions[shortname] then return end; -- чтобы по сто раз не вносить одну и ту же викторину на хотлоудах 
    
    if isfunction(funcortable) then --делаем так чтобы таблица не попала в другую таблицу ))
        self.Questions[shortname] = funcortable
        return;
    end;
    
    self.Questions[shortname] = {funcortable[1],funcortable[2]}
    
    if willsave then
        SaveQuestion(funcortable)
    end;
end;

quiz:AddQuestion("math_plus",{})

function quiz:StartVictory(concretly)
    concretly = self.Questions[concretly or table.Random(self.Questions)] -- если у нас админ запустил викторину то будет та которую он выбрал. если сервак то рандомная т.к. concretly == nil. или null. кто в каком языке живёт.

    NotifyPlayers(SortTextFromFunctionOrTable(concretly,1))

    timer.Simple(self.TimeToAnswer,function()
        QuizEnding()
    end)

    return concretly;
end;

local function SortTextFromFunctionOrTable(func,argument)
    return isfunction(func) and select(argument,func()) or func[argument]; -- не буду расписывать как работает эта шайтан машина, пусть будет магией.
end;

local function QuizEnding()
    local players = quiz.StartedQuestion.GivedAnswer
    local RightAnswer = "Правильный ответ был: "..quiz.StartedQuestion.RightAnswer.."."
    local text = "Никто не дал правильного ответа. "..RightAnswer

    if #players > 0 then
        text = "Игроки: "..table.concat(players,", ",1).." дали правильный ответ. "..RightAnswer
    end;

    NotifyPlayers(text)

    quiz.StartedQuestion = nil
    quiz.NextQuestion = CurTime()+quiz.QuestionEveryHowSeconds
end;
local function NotifyPlayers(text) -- делаем неповторяющийся код
    for k,v in pairs(player.GetAll())do --фор ка вэ ин пейрс. короче standart theme for Lua Developers.
        v:ChatPrint(text)
    end;
end;
local function SaveQuestion(questiontable)
    questiontable = util.TableToJSON() -- сериализуем таблицу луа под ЖСОН чтобы сохранить, будет как своя!!!! да ещё и постоянная!
    file.Write("quiz.json",questiontable)
end;

local function AddAdminQuestion(client,data)
    if !client:IsAdmin() then return end; -- проверяем всю информацию полученную в интернетах, без этого в нынешнее время никуда. повсюду люди с луараннерами пытающимися проверить сервера на прочность

    quiz:AddQuestion(data[1],data[2],true)
end;

local function StartAdminQuestion(client,data)
    if !client:IsAdmin() then return end; --                     ^^^
    
    if quiz.Questions[data] then -- проверяем на существующую викторину, не нужны нам красные ошибки в консоли
        quiz:StartVictory(data)
    end;
end;


-- .-[[           Получаем информацию от Админом. Или ЛжеАдминов. Обязательно её нужно проверить.           ]]-.
netstream.Hook("aw_GetAdminQuestion",function(client,data)AddAdminQuestion(client,data)end);
netstream.Hook("aw_StartAdminQuestion",function(client,data)StartAdminQuestion(client,data)end);

-- .-[[         Захукиваем досмерти сервер, прям как тот чел из доты (я в неё не играю сори что кликуху забыл)          ]]
hook.Add("Think","aw_Victory",function()
    local question = quiz.StartedQuestion
    if !question then
        if CurTime() > quiz.NextQuestion then
            question = quiz:StartVictory()
            quiz.StartedQuestion.GivedAnswer = {}
            quiz.StartedQuestion.RightAnswer = SortTextFromFunctionOrTable(question,2)
        end;
    end;
end);
hook.Add("PlayerSay","aw_Victory",function(client,text)
    if quiz.StartedQuestion then
        text = text:lower()
        if text:match(quiz.StartedQuestion.RightAnswer) then
            quiz.StartedQuestion.GivedAnswer[client] = true -- делаем именно так чтобы игроки не засоряли таблицу а мы не тратили мощность процессора по поиску по таблице по значению. кстати подобный матчинг есть у меня на гитхабе, не рекомендую его использовать на постоянной основе.
            return "";
        end;
    end;
    return text;
end);
