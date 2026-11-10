const sized = (id, name, small, medium, large) => ({
  id,
  name,
  options: [
    { id: 'S', label: 'Small', priceCents: small },
    { id: 'M', label: 'Medium', priceCents: medium },
    { id: 'L', label: 'Large', priceCents: large },
  ],
});

const single = (id, name, price) => ({
  id,
  name,
  options: [{ id: 'R', label: 'Regular', priceCents: price }],
});

const companies = [
  {
    id: 'pizzeria',
    name: 'Noble Oven Pizzeria',
    description: 'Wood-fired oven pizzas.',
    products: [
      sized('supreme', 'Supreme', 3890, 5290, 6690),
      sized('pepperoni', 'Pepperoni', 3490, 4890, 6290),
      sized('chicken-cheese', 'Chicken & Cream Cheese', 3690, 5090, 6490),
      sized('margherita', 'Margherita', 3290, 4690, 6090),
    ],
  },
  {
    id: 'burgers',
    name: 'Hot Griddle Burgers',
    description: 'Handcrafted burgers made to order.',
    products: [
      single('vegan', 'Vegan', 3190),
      single('classic', 'Classic', 2990),
      single('egg-burger', 'Egg Burger', 2690),
      single('double', 'Double', 3690),
    ],
  },
  {
    id: 'japanese',
    name: 'Japa Express',
    description: 'Yakisoba and hot rolls prepared on order.',
    products: [
      single('beef-yakisoba', 'Beef Yakisoba', 3490),
      single('chicken-yakisoba', 'Chicken Yakisoba', 3190),
      single('mixed-yakisoba', 'Mixed Yakisoba', 3790),
      single('philly-hot-roll', 'Philadelphia Hot Roll', 2990),
    ],
  },
  {
    id: 'juices',
    name: 'Fresh Fruit Juices',
    description: 'Natural juices made from fresh fruit.',
    products: [
      sized('orange', 'Orange', 890, 1190, 1490),
      sized('pineapple', 'Pineapple', 990, 1290, 1590),
      sized('guava', 'Guava', 950, 1250, 1550),
      sized('acerola', 'Acerola', 900, 1200, 1500),
    ],
  },
];

function findCompany(companyId) {
  return companies.find((company) => company.id === companyId);
}

function resolveItem(companyId, productId, optionId) {
  const company = findCompany(companyId);
  const product = company?.products.find((candidate) => candidate.id === productId);
  const option = product?.options.find((candidate) => candidate.id === optionId);
  return option ? { company, product, option } : null;
}

module.exports = { companies, findCompany, resolveItem };
