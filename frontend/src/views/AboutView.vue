<template>
  <div class="about">
    <h1>关于项目</h1>
    <p>这是一个使用 Vue 3 和 Express 构建的全栈应用示例。</p>

    <div class="tech-stack">
      <h2>技术栈</h2>
      <div class="tech-grid">
        <div class="tech-item">
          <h3>前端</h3>
          <ul>
            <li>Vue 3</li>
            <li>TypeScript</li>
            <li>Vite</li>
            <li>Vue Router</li>
            <li>Pinia</li>
          </ul>
        </div>
        <div class="tech-item">
          <h3>后端</h3>
          <ul>
            <li>Express.js</li>
            <li>TypeScript</li>
            <li>Node.js</li>
            <li>Redis</li>
            <li>MongoDB/PostgreSQL</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.about {
  max-width: 800px;
  margin: 0 auto;
}

.tech-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  margin-top: 1rem;
}

.tech-item {
  padding: 1rem;
  border: 1px solid #ddd;
  border-radius: 8px;
}

.tech-item h3 {
  margin-top: 0;
  color: #007bff;
}

.tech-item ul {
  list-style-type: none;
  padding: 0;
}

.tech-item li {
  padding: 0.25rem 0;
}

@media (max-width: 768px) {
  .tech-grid {
    grid-template-columns: 1fr;
  }
}
</style>