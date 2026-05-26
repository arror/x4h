import { url } from "@kit.ArkTS";

export interface Parser {

  get scheme(): string

  parse(link: url.URL): object
}