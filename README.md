# semantix-test

O arquivo banktest.jl define funções para realizaço de análise de correlação canônica, tanto para variáveis numéricas quanto categóricas.

O arquivo banktest.jl e o arquivo bank-full.csv devem estar na mesma pasta. Presume-se que ao incluir banktest.jl no REPL pwd() seja o diretório onde esses arquivos se encontram. Nesse caso, basta executar o comando include(joinpath(pwd(),"banktest.jl")).

Com a inclusão desse arquivo, os dados de bank-full.csv já são carregados em uma variável denominada data.

A documentação das funções desenvolvidas foi inclusa. Dessa forma, basta executar (no REPL) ?func_name para visualizar a documentação. As funções mais importantes são: getlevels, dummify e cancorr.
