-- As unidades do catálogo passam a ser as da nota fiscal: "kg" e "un"
-- (issue #175).
--
-- No teste da E7, a Merendeira 1 pediu as unidades como vêm na nota fiscal do
-- fornecedor, que é onde elas conferem o que recebem. As sugestões do app e da
-- web ficam só com "kg" e "un"; qualquer outra unidade continua possível,
-- digitada no catálogo, porque a coluna é texto livre (decisão 8 da E4).
--
-- O que já está no catálogo acompanha: "quilo" vira "kg", e "unidade", "pote",
-- "lata" e "litro" viram "un". Eram as únicas em uso quando a issue foi
-- aberta. Outra unidade, se houver, fica como está.
--
-- A unidade só mora em `food_item.default_unit`: o dia guarda o gênero e a
-- quantidade, e o documento lê a unidade do catálogo. Por isso os mapas, mesmo
-- os que já saíram em documento, passam a mostrar a unidade nova sem tocar em
-- nenhum deles. Os documentos gerados são arquivos e não mudam.

update public.food_item
set default_unit = 'kg'
where lower(btrim(default_unit)) = 'quilo';

update public.food_item
set default_unit = 'un'
where lower(btrim(default_unit)) in ('unidade', 'pote', 'lata', 'litro');
