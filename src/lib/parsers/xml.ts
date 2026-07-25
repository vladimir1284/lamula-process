// Minimal XML tree parser, deliberately not general-purpose: covers only what Rainbow5's `.vol`
// header actually uses (nested elements, quoted attributes, self-closing tags, leaf text). No
// entity decoding, no namespaces, no CDATA — none appear in the verified fixtures (docs/formatos.md).
export interface XmlElement {
	tag: string;
	attrs: Record<string, string>;
	children: XmlElement[];
	text: string;
}

const TAG_RE = /<(\/?)([a-zA-Z_][\w.-]*)((?:\s+[\w:.-]+="[^"]*")*)\s*(\/?)>/g;
const ATTR_RE = /([\w:.-]+)="([^"]*)"/g;

export function parseXml(xml: string): XmlElement {
	const root: XmlElement = { tag: '#root', attrs: {}, children: [], text: '' };
	const stack: XmlElement[] = [root];
	let lastIndex = 0;
	let match: RegExpExecArray | null;

	TAG_RE.lastIndex = 0;
	while ((match = TAG_RE.exec(xml))) {
		const [full, closing, tag, attrString, selfClose] = match;
		const text = xml.slice(lastIndex, match.index);
		if (text.trim().length > 0) {
			stack[stack.length - 1].text += text;
		}
		lastIndex = match.index + full.length;

		if (closing) {
			if (stack.length > 1) stack.pop();
			continue;
		}

		const attrs: Record<string, string> = {};
		ATTR_RE.lastIndex = 0;
		let attrMatch: RegExpExecArray | null;
		while ((attrMatch = ATTR_RE.exec(attrString))) {
			attrs[attrMatch[1]] = attrMatch[2];
		}

		const el: XmlElement = { tag, attrs, children: [], text: '' };
		stack[stack.length - 1].children.push(el);
		if (!selfClose) stack.push(el);
	}

	return root;
}

export function child(el: XmlElement, tag: string): XmlElement | undefined {
	return el.children.find((c) => c.tag === tag);
}

export function children(el: XmlElement, tag: string): XmlElement[] {
	return el.children.filter((c) => c.tag === tag);
}

export function requireChild(el: XmlElement, tag: string): XmlElement {
	const found = child(el, tag);
	if (!found) throw new Error(`expected <${el.tag}> to have a <${tag}> child`);
	return found;
}

export function childText(el: XmlElement, tag: string): string | undefined {
	return child(el, tag)?.text.trim();
}

export function requireAttr(el: XmlElement, attr: string): string {
	const value = el.attrs[attr];
	if (value === undefined) throw new Error(`expected <${el.tag}> to have attribute "${attr}"`);
	return value;
}
