FROM ubuntu:latest

RUN apt update && apt install -y cabal-install ghc libghc-zlib-dev locales libghc-yesod-dev yesod sendmail
RUN locale-gen en_US.UTF-8

RUN mkdir -p /opt/app

WORKDIR /opt/app

COPY . .

RUN cabal update

RUN cabal build

CMD ["cabal", "run"]
