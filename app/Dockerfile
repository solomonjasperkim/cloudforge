FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY CloudForge.Api/CloudForge.Api.csproj CloudForge.Api/
RUN dotnet restore CloudForge.Api/CloudForge.Api.csproj
COPY CloudForge.Api/ CloudForge.Api/
RUN dotnet publish CloudForge.Api/CloudForge.Api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "CloudForge.Api.dll"]
