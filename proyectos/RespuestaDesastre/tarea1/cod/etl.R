# Cargar librerías
library(readxl)
library(dplyr)
library(tidyr)
library(sp)

# Cargar datos
path <- '../dat/refugios_nayarit.xlsx'
df <- lapply(excel_sheets(path), read_xlsx, path=path, col_names=FALSE, skip=6) %>% bind_rows()

# Nombre de columnas
names(df) <-c('id','refugio','municipio','direccion','tipo','servicios','capacidad','lat','long',
              'alt','responsable','tel')

# Parsear `lat` y `long`
df <- df %>%
  filter(!(is.na(id) | is.na(lat) | is.na(long))) %>%         # Sin NAs en [id,lat,long]
  mutate(lat=gsub(' ','',lat), long=gsub(' ','',long)) %>%    # Quitar espacios
  mutate(lat=gsub('º\'|°\'','º',lat)) %>%                     # Quitar casos raros
  separate(lat, into=paste0('lat', 1:4), sep='[^0-9]') %>% 
  separate(long, into=paste0('long', 1:4), sep='[^0-9]') %>% 
  mutate(lat=paste0(lat1,'d',lat2,'m',lat3,'.',lat4,'s')) %>% 
  mutate(long=paste0(long1,'d',long2,'m',long3,'.',long4,'s')) %>% 
  select(-c(lat1,lat2,lat3,lat4,long1,long2,long3,long4)) # Quitar columnas temporales

# Convertir coordenadas de STR a DMS a NUM y quitar casos que no se parsean con patrón
df <- df %>%
  mutate(lat=char2dms(from=df$lat, chd='d', chm='m', chs='s') %>% as.numeric()) %>% 
  mutate(long=char2dms(from=df$long, chd='d', chm='m', chs='s') %>% as.numeric()) %>% 
  filter(!(is.na(responsable) | is.na(tel)))

# Convertir datos planos a SpatialPointDataFrame
proj <- CRS("+proj=longlat +datum=WGS84")
df <- SpatialPointsDataFrame(coords=df %>% select(c(long, lat)), data=df, proj4string=proj)

# Usuario mete su localización
user_lon <- 22.48
user_lat <- 105.35
user_loc <- SpatialPoints(coords=matrix(data=c(user_lon,user_lat), nrow=1), proj4string=proj)

# Distancia a todos los puntos
df$dist <- spDists(x=user_loc, y=df, longlat=TRUE)[1,]

# Seleccionar el refucio más cercano
df@data %>% filter(dist == df@data$dist %>% min())