# DAFLs Invent: o backend com a web embutida (dafls_inventario.jar, gerado pelo empacotar.sh).
FROM eclipse-temurin:21-jre

RUN groupadd --system invent && useradd --system --gid invent --home /app invent
WORKDIR /app
COPY dafls_inventario.jar /app/dafls_inventario.jar

USER invent
EXPOSE 9000
# Sem -Xms/-Xmx: vale a ergonomia padrão do Java 21 (heap máximo = 1/4 da memória visível ao container). Para ajustar
# depois, sem reconstruir a imagem: JAVA_TOOL_OPTIONS no .env (ex.: -XX:MaxRAMPercentage=50) e docker compose up -d app.
ENTRYPOINT ["java", "-jar", "/app/dafls_inventario.jar"]
