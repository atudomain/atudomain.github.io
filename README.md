# My personal github pages site

Link to jekyll: https://jekyllrb.com/

## Create docker image

Create docker image for Jekyll development:
```
docker build . -t jekyll-github
```

## Run docker image
```
docker run --rm -it -p 127.0.0.1:4000:4000 -v $(pwd):/app jekyll-github bash
```

## Install dependencies

```
bundle install
```

## Serve page locally

```
bundle exec jekyll serve --host=0.0.0.0
```
