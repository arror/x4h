import { url } from "@kit.ArkTS";
import { ParseFinalMask } from "./FinalMask";
import { ParseNetwork } from "./Network";
import { ParseSecurity } from "./Security";

export function ParseStreamSettings(params: url.URLParams): object {
  const streamSettings: Record<string, Object> = {}
  ParseNetwork(params, streamSettings)
  ParseSecurity(params, streamSettings)
  ParseFinalMask(params, streamSettings)
  return streamSettings
}