#pragma once
// AetherScaler Lifeline 0.2 compact multilingual in-game panel.
// GPL-3.0-or-later when combined with OptiScaler.
#include "../Config.h"
#include "../State.h"
#include "../OptiTypes.h"
#include <imgui/imgui.h>
#include <array>
#include <fstream>
#include <filesystem>
#include <string>
namespace LifelineI18n {
struct Row { const char* code; const char* nativeName; const char* language; const char* upscaler; const char* fg; const char* fps; const char* hint; };
inline constexpr std::array<Row,8> rows{{
{"en-US","English","Language","Upscaler","Frame generation","FPS overlay","Use the external manager to change the backend safely."},
{"zh-TW","繁體中文","語言","升頻器","畫格生成","FPS 顯示","請使用外部管理器安全切換升頻器。"},
{"ja-JP","日本語","言語","アップスケーラー","フレーム生成","FPS 表示","バックエンド変更は外部マネージャーを使用してください。"},
{"ko-KR","한국어","언어","업스케일러","프레임 생성","FPS 표시","백엔드 변경은 외부 관리자를 사용하세요."},
{"de-DE","Deutsch","Sprache","Upscaler","Frame-Generierung","FPS-Anzeige","Backend sicher im externen Manager ändern."},
{"fr-FR","Français","Langue","Upscaler","Génération d’images","Affichage FPS","Utilisez le gestionnaire externe pour changer de moteur."},
{"es-ES","Español","Idioma","Reescalador","Generación de fotogramas","Indicador FPS","Use el gestor externo para cambiar el backend."},
{"pt-BR","Português (Brasil)","Idioma","Upscaler","Geração de quadros","Exibição de FPS","Use o gerenciador externo para trocar o backend."}
}};
inline int& Index(){static int i=-1;return i;}
inline std::filesystem::path LanguagePath(){return std::filesystem::current_path()/"LifelineLanguage.txt";}
inline void EnsureLoaded(){if(Index()>=0)return;Index()=0;std::ifstream f(LanguagePath());std::string s;if(f&&std::getline(f,s)){for(size_t i=0;i<rows.size();++i)if(s==rows[i].code){Index()=(int)i;break;}}}
inline const Row& R(){EnsureLoaded();return rows[(size_t)Index()];}
inline const ImWchar* GlyphRanges(ImFontAtlas* a){EnsureLoaded();auto c=std::string(R().code);if(c=="zh-TW")return a->GetGlyphRangesChineseFull();if(c=="ja-JP")return a->GetGlyphRangesJapanese();if(c=="ko-KR")return a->GetGlyphRangesKorean();return a->GetGlyphRangesDefault();}
inline void Save(){std::ofstream f(LanguagePath(),std::ios::trunc);if(f)f<<R().code;}
inline Upscaler ConfiguredUpscaler(){auto c=Config::Instance();auto api=State::Instance().api;if(api==API::DX11)return c->Dx11Upscaler.value_or_default();if(api==API::Vulkan)return c->VulkanUpscaler.value_or_default();return c->Dx12Upscaler.value_or_default();}
inline void RenderMiniPanel(){EnsureLoaded();ImGui::SeparatorText("AetherScaler Lifeline");int old=Index();ImGui::SetNextItemWidth(180.0f);if(ImGui::Combo(R().language,&Index(),[](void*,int idx,const char** out){*out=rows[(size_t)idx].nativeName;return true;},nullptr,(int)rows.size())){Save();}auto u=ConfiguredUpscaler();auto n=UpscalerDisplayName(u,State::Instance().api);ImGui::Text("%s: %s",R().upscaler,n.c_str());auto c=Config::Instance();bool fg=c->FGEnabled.value_or_default();if(ImGui::Checkbox(R().fg,&fg)){c->FGEnabled=fg;if(fg)State::Instance().fgChanged=true;}bool fps=c->ShowFps.value_or_default();if(ImGui::Checkbox(R().fps,&fps)){c->ShowFps=fps;}ImGui::TextDisabled("%s",R().hint);if(old!=Index())ImGui::TextDisabled("Restart the game if glyphs are missing after changing language.");}
}
