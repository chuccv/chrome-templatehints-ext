const PARAM = "templatehints";
const VALUE = "magento";

chrome.action.onClicked.addListener(async (tab) => {
  if (!tab || !tab.url || !/^https?:/i.test(tab.url)) return;

  const url = new URL(tab.url);
  if (url.searchParams.has(PARAM)) {
    url.searchParams.delete(PARAM);
  } else {
    url.searchParams.set(PARAM, VALUE);
  }
  await chrome.tabs.update(tab.id, { url: url.toString() });
});
